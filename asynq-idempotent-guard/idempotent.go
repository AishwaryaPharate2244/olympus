// Copyright 2020 Kentaro Hibino. All rights reserved.
// Use of this source code is governed by a MIT license
// that can be found in the LICENSE file.

// Package idempotent guards an asynq.Handler against re-running its side
// effect when a task is redelivered after already completing once.
//
// asynq guarantees at-least-once execution: if a worker process finishes a
// task's side effect but dies before asynq records the task as done (a
// crash, an OOM kill, a missed heartbeat), the task's lease expires and the
// recoverer redelivers it -- possibly to a different worker process -- which
// runs the handler again. The Unique option does not cover this: it
// deduplicates tasks at enqueue time by type+payload+queue, not repeat
// executions of one already-enqueued task instance. Guard closes that gap
// for handlers whose side effects are not naturally safe to repeat.
package idempotent

import (
	"context"
	"fmt"
	"time"

	"github.com/hibiken/asynq"
	asynqcontext "github.com/hibiken/asynq/internal/context"
	"github.com/redis/go-redis/v9"
)

const (
	statusInProgress = "in_progress"
	statusDone       = "done"
)

// Guard deduplicates task execution across redeliveries of the same task ID,
// using a Redis-backed ledger shared by every asynq server on the broker --
// the same failure mode Guard closes can hand a redelivered task to a
// different process than the one that ran it the first time.
type Guard struct {
	rc  redis.UniversalClient
	ttl time.Duration
}

// NewGuard creates a Guard backed by the given redis connection. ttl bounds
// both how long a claim may be held before it's considered abandoned and how
// long a completed task is remembered to dedupe a late redelivery; it should
// comfortably exceed the wrapped handler's expected processing time.
func NewGuard(rco asynq.RedisConnOpt, ttl time.Duration) *Guard {
	rc, ok := rco.MakeRedisClient().(redis.UniversalClient)
	if !ok {
		panic(fmt.Sprintf("idempotent.NewGuard: unsupported RedisConnOpt type %T", rco))
	}
	if ttl <= 0 {
		panic("idempotent.NewGuard: ttl must be positive")
	}
	return &Guard{rc: rc, ttl: ttl}
}

// Close closes the connection to redis.
func (g *Guard) Close() error {
	return g.rc.Close()
}

// Wrap returns a Handler that runs next at most once per task ID: a
// redelivery of a task next already completed is skipped rather than
// re-run, and a redelivery that arrives while the first attempt is still in
// flight is bounced back to asynq's own retry/backoff instead of running
// concurrently with it.
func (g *Guard) Wrap(next asynq.Handler) asynq.Handler {
	return asynq.HandlerFunc(func(ctx context.Context, t *asynq.Task) error {
		id, ok := asynqcontext.GetTaskID(ctx)
		if !ok {
			return fmt.Errorf("idempotent: provided context is missing task ID value")
		}
		key := ledgerKey(id)

		claimed, err := g.rc.SetNX(ctx, key, statusInProgress, g.ttl).Result()
		if err != nil {
			return fmt.Errorf("idempotent: redis command failed: %w", err)
		}
		if !claimed {
			status, err := g.rc.Get(ctx, key).Result()
			if err != nil {
				return fmt.Errorf("idempotent: redis command failed: %w", err)
			}
			if status == statusDone {
				return nil // already completed by a previous delivery; nothing to do.
			}
			return fmt.Errorf("idempotent: task %s is already being processed", id)
		}

		if err := next.ProcessTask(ctx, t); err != nil {
			if delErr := g.rc.Del(ctx, key).Err(); delErr != nil {
				return fmt.Errorf("idempotent: handler error: %w (also failed to release claim: %v)", err, delErr)
			}
			return err
		}

		if err := g.rc.Set(ctx, key, statusDone, g.ttl).Err(); err != nil {
			return fmt.Errorf("idempotent: redis command failed: %w", err)
		}
		return nil
	})
}

func ledgerKey(taskID string) string {
	return "asynq:idempotent:" + taskID
}
