# x/idempotent: at-most-once execution guard for asynq

Target: [`hibiken/asynq`](https://github.com/hibiken/asynq) — a real, actively
maintained Redis-backed task queue for Go. Verified against the actual
source (cloned at `d135f1439bee74e989b7f9b41ecd542cc87f024a`) and built/tested
against the real published module (`x`'s own `go.mod` pins
`github.com/hibiken/asynq v0.25.0`), not assumed from memory.

## Problem Description

asynq delivers tasks at least once, not exactly once, and nothing in the
library or its docs closes that gap for a handler's side effects:

1. A worker dequeues a task and calls the handler. The handler's side
   effect runs (a charge, an email, a write) and returns `nil`.
2. Before `processor.handleSucceededMessage` reaches `broker.Done` — the
   process is killed, OOMed, or the host dies — nothing tells Redis the
   task finished (`processor.go:250-255`).
3. The worker's heartbeat goroutine dies with it, so `ExtendLease` stops
   being called (`heartbeat.go:190-201`). The task's lease expires.
4. `recoverer.recoverLeaseExpiredTasks` polls for exactly this
   (`recoverer.go:89-104`), and redelivers the task — the doc comment on
   `ErrLeaseExpired` says as much: *"The worker may have crashed or got
   cutoff from the network."*
5. Whichever worker (possibly a different process — asynq is meant to run
   horizontally scaled) dequeues it next runs the handler again. The side
   effect executes twice.

The `Unique` option does not cover this — confirmed from its own doc
comment in `client.go:160-170`: it prevents *enqueueing* a second task
with the same type+payload+queue within a TTL. It says nothing about a
single already-enqueued task instance being *executed* twice after
redelivery, because it operates at `Client.Enqueue`, not inside the
processor's dequeue/execute path. Neither the README nor `docs/` mention
"idempotent," "at least once," or "duplicate" anywhere — this isn't
called out as the caller's responsibility, it's just silent.

## Solution & Code

`x/idempotent.Guard` wraps an `asynq.Handler` and lets it run at most once
per task ID, using a Redis-backed ledger (`asynq:idempotent:<taskID>`):

- **Claim**: `SET key in_progress NX EX ttl` — atomic; exactly one caller
  can hold this per task ID while it exists.
- **On handler success**: overwrite the key to `done EX ttl`, so a late
  redelivery of the same task ID finds it already finished and is skipped
  (`Wrap` returns `nil` without re-invoking the handler).
- **On handler failure**: delete the key, releasing the claim so asynq's
  own retry/backoff can legitimately run the handler again — Guard must
  not turn a real failure into a permanent skip.
- **On a concurrent claim attempt** (the harder case: a redelivery arrives
  while the first attempt is still executing): the `SET NX` fails, so the
  second caller reads the ledger value. `in_progress` → return an error
  and let asynq's normal retry/backoff handle it, rather than either
  blocking or running concurrently with the in-flight attempt.

This follows the existing `x/rate` extension's own conventions exactly
(`NewGuard(rco asynq.RedisConnOpt, ...)`, panics on a bad `RedisConnOpt` or
invalid config, `Close()` closes the client, task ID pulled from context via
the same `internal/context.GetTaskID` that `x/rate.Semaphore` already uses)
so it reads as an extension of the library, not a bolt-on.

**Deliberately out of scope:** this does not touch `processor.go`,
`recoverer.go`, or lease/heartbeat semantics — those are correct and
necessary for at-least-once delivery. Guard is purely additive middleware
for handlers that need stronger guarantees; asynq users who don't need it
pay nothing. It's also one production file, not split across two — the
claim/release/skip logic is one cohesive concern, and splitting it further
would be padding, not structure.

## Tests

All 5 pass under `go test -race` against a real Redis instance (not a
mock) and the real published `asynq` module:

| Test | Proves |
|---|---|
| `TestNewGuard_Panics` | Bad `RedisConnOpt` / non-positive ttl are rejected at construction, matching `x/rate`'s own panic convention |
| `TestGuard_Wrap_MissingTaskID` | A context without asynq's task metadata fails clearly instead of silently mis-keying the ledger |
| `TestGuard_Wrap_SkipsCompletedRedelivery` | **Reproduces the bug directly**: same task ID delivered twice: the handler runs once; the second call returns `nil` without re-running it |
| `TestGuard_Wrap_ConcurrentRedelivery` | **The harder race**: a redelivery of the same task ID arrives *while the first attempt is still executing* — driven entirely by channels (`claimed`, `proceed`), no sleeps, no timing assumptions. Both calls share one `Guard` and one task ID, so this can only pass if the Redis claim is genuinely atomic |
| `TestGuard_Wrap_ReleasesClaimOnFailure` | A real handler failure is *not* mistaken for completion — the next delivery still runs the handler, proving Guard doesn't break normal retry semantics |

Every assertion is an exact value (`want 1`, `want 2`, exact error strings)
— never a lower bound.

## How to apply

```
git clone https://github.com/hibiken/asynq
cd asynq
git am /path/to/0001-add-x-idempotent.patch   # or copy idempotent*.go into x/idempotent/
cd x
go test -race ./idempotent/...
```

The patch's commit author is a placeholder (`dev <dev@example.com>`) —
reword it (`git commit --amend --author`) before submitting under your own
name.

Whether to also open this as a real PR against `hibiken/asynq` upstream is
a separate decision — this patch is written to be genuinely mergeable, but
that's a call for you to make with the maintainers, not something done on
your behalf here.
