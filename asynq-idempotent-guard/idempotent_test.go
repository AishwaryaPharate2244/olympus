package idempotent

import (
	"context"
	"flag"
	"sync/atomic"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/hibiken/asynq"
	"github.com/hibiken/asynq/internal/base"
	asynqcontext "github.com/hibiken/asynq/internal/context"
	"github.com/redis/go-redis/v9"
)

var (
	redisAddr string
	redisDB   int
)

func init() {
	flag.StringVar(&redisAddr, "redis_addr", "localhost:6379", "redis address to use in testing")
	flag.IntVar(&redisDB, "redis_db", 15, "redis db number to use in testing")
}

func getRedisConnOpt(tb testing.TB) asynq.RedisConnOpt {
	tb.Helper()
	return asynq.RedisClientOpt{Addr: redisAddr, DB: redisDB}
}

func newTestContext(tb testing.TB, taskID string) (context.Context, context.CancelFunc) {
	tb.Helper()
	return asynqcontext.New(context.Background(), &base.TaskMessage{
		ID:    taskID,
		Type:  "test_task",
		Queue: "default",
	}, time.Now().Add(time.Minute))
}

func TestNewGuard_Panics(t *testing.T) {
	tests := []struct {
		desc      string
		connOpt   asynq.RedisConnOpt
		ttl       time.Duration
		wantPanic string
	}{
		{
			desc:      "unsupported RedisConnOpt",
			connOpt:   &badConnOpt{},
			ttl:       time.Minute,
			wantPanic: "idempotent.NewGuard: unsupported RedisConnOpt type *idempotent.badConnOpt",
		},
		{
			desc:      "zero ttl",
			ttl:       0,
			wantPanic: "idempotent.NewGuard: ttl must be positive",
		},
		{
			desc:      "negative ttl",
			ttl:       -time.Second,
			wantPanic: "idempotent.NewGuard: ttl must be positive",
		},
	}

	for _, tt := range tests {
		t.Run(tt.desc, func(t *testing.T) {
			defer func() {
				r := recover()
				if r == nil {
					t.Fatalf("%s: NewGuard did not panic, want panic %q", tt.desc, tt.wantPanic)
				}
				if r.(string) != tt.wantPanic {
					t.Errorf("%s: NewGuard panicked with %q, want %q", tt.desc, r, tt.wantPanic)
				}
			}()
			opt := tt.connOpt
			if opt == nil {
				opt = getRedisConnOpt(t)
			}
			NewGuard(opt, tt.ttl)
		})
	}
}

func TestGuard_Wrap_MissingTaskID(t *testing.T) {
	opt := getRedisConnOpt(t)
	guard := NewGuard(opt, time.Minute)
	defer guard.Close()

	var runs int32
	wrapped := guard.Wrap(asynq.HandlerFunc(func(ctx context.Context, task *asynq.Task) error {
		atomic.AddInt32(&runs, 1)
		return nil
	}))

	err := wrapped.ProcessTask(context.Background(), asynq.NewTask("test_task", nil))
	wantErr := "idempotent: provided context is missing task ID value"
	if err == nil || err.Error() != wantErr {
		t.Fatalf("ProcessTask() error = %v, want %q", err, wantErr)
	}
	if got := atomic.LoadInt32(&runs); got != 0 {
		t.Fatalf("handler ran %d times, want 0", got)
	}
}

// TestGuard_Wrap_SkipsCompletedRedelivery reproduces the bug directly: a task
// completes, and the *same* task ID is delivered again (asynq's own
// contract after a lease-expiry retry) before proving the fix closes it.
func TestGuard_Wrap_SkipsCompletedRedelivery(t *testing.T) {
	opt := getRedisConnOpt(t)
	rc := opt.MakeRedisClient().(redis.UniversalClient)
	defer rc.Close()

	taskID := uuid.NewString()
	rc.Del(context.Background(), ledgerKey(taskID))

	guard := NewGuard(opt, time.Minute)
	defer guard.Close()

	var runs int32
	wrapped := guard.Wrap(asynq.HandlerFunc(func(ctx context.Context, task *asynq.Task) error {
		atomic.AddInt32(&runs, 1)
		return nil
	}))

	ctx, cancel := newTestContext(t, taskID)
	defer cancel()
	task := asynq.NewTask("test_task", nil)

	if err := wrapped.ProcessTask(ctx, task); err != nil {
		t.Fatalf("1st delivery: ProcessTask() error = %v, want nil", err)
	}
	if got := atomic.LoadInt32(&runs); got != 1 {
		t.Fatalf("after 1st delivery: handler ran %d times, want 1", got)
	}

	// Simulate the broker redelivering the identical task after the first
	// worker's lease expired without a done/ack ever landing.
	if err := wrapped.ProcessTask(ctx, task); err != nil {
		t.Fatalf("2nd delivery (redelivery): ProcessTask() error = %v, want nil", err)
	}
	if got := atomic.LoadInt32(&runs); got != 1 {
		t.Fatalf("after redelivery: handler ran %d times, want exactly 1 (this is the bug Guard closes)", got)
	}
}

// TestGuard_Wrap_ConcurrentRedelivery exercises the harder race: a
// redelivery of the same task ID arrives while the first attempt is still
// executing. Both calls share one Guard and one task ID, so this can only
// pass if the claim is truly atomic, not because two independent handlers
// each got their own bookkeeping. No sleeps: ordering is driven entirely by
// channels.
func TestGuard_Wrap_ConcurrentRedelivery(t *testing.T) {
	opt := getRedisConnOpt(t)
	rc := opt.MakeRedisClient().(redis.UniversalClient)
	defer rc.Close()

	taskID := uuid.NewString()
	rc.Del(context.Background(), ledgerKey(taskID))

	guard := NewGuard(opt, time.Minute)
	defer guard.Close()

	var runs int32
	claimed := make(chan struct{})
	proceed := make(chan struct{})
	wrapped := guard.Wrap(asynq.HandlerFunc(func(ctx context.Context, task *asynq.Task) error {
		atomic.AddInt32(&runs, 1)
		close(claimed)
		<-proceed
		return nil
	}))

	ctx, cancel := newTestContext(t, taskID)
	defer cancel()
	task := asynq.NewTask("test_task", nil)

	firstErrCh := make(chan error, 1)
	go func() { firstErrCh <- wrapped.ProcessTask(ctx, task) }()

	<-claimed // first delivery genuinely holds the claim before we race it

	secondErr := wrapped.ProcessTask(ctx, task)
	if secondErr == nil {
		t.Fatal("concurrent redelivery: ProcessTask() error = nil, want error while first attempt is in flight")
	}
	if got := atomic.LoadInt32(&runs); got != 1 {
		t.Fatalf("while first attempt in flight: handler ran %d times, want exactly 1", got)
	}

	close(proceed)
	if err := <-firstErrCh; err != nil {
		t.Fatalf("first delivery: ProcessTask() error = %v, want nil", err)
	}
	if got := atomic.LoadInt32(&runs); got != 1 {
		t.Fatalf("final: handler ran %d times, want exactly 1", got)
	}
}

// TestGuard_Wrap_ReleasesClaimOnFailure proves Guard does not turn a
// legitimate task failure into a permanent skip: asynq's normal retry path
// must still be able to run the handler again.
func TestGuard_Wrap_ReleasesClaimOnFailure(t *testing.T) {
	opt := getRedisConnOpt(t)
	rc := opt.MakeRedisClient().(redis.UniversalClient)
	defer rc.Close()

	taskID := uuid.NewString()
	rc.Del(context.Background(), ledgerKey(taskID))

	guard := NewGuard(opt, time.Minute)
	defer guard.Close()

	var runs int32
	wrapped := guard.Wrap(asynq.HandlerFunc(func(ctx context.Context, task *asynq.Task) error {
		n := atomic.AddInt32(&runs, 1)
		if n == 1 {
			return errFirstAttempt
		}
		return nil
	}))

	ctx, cancel := newTestContext(t, taskID)
	defer cancel()
	task := asynq.NewTask("test_task", nil)

	if err := wrapped.ProcessTask(ctx, task); err != errFirstAttempt {
		t.Fatalf("1st attempt: ProcessTask() error = %v, want %v", err, errFirstAttempt)
	}

	// asynq's retry path redelivers the same task ID after a real failure.
	if err := wrapped.ProcessTask(ctx, task); err != nil {
		t.Fatalf("retry after failure: ProcessTask() error = %v, want nil", err)
	}
	if got := atomic.LoadInt32(&runs); got != 2 {
		t.Fatalf("handler ran %d times, want exactly 2 (failure must not block a legitimate retry)", got)
	}
}

var errFirstAttempt = &testError{"simulated failure on first attempt"}

type testError struct{ msg string }

func (e *testError) Error() string { return e.msg }

type badConnOpt struct{}

func (b *badConnOpt) MakeRedisClient() interface{} { return nil }
