# Exactly-once processing: suppressing duplicate execution after ack-loss

## The problem

A worker pulls a job off the queue, runs its side effect (charge a card,
send an email, write a row), and then acks the message so the broker
deletes it. If the ack never lands — the worker crashes right after
finishing the work, or the ack is dropped on the way back — the broker has
no way to know the job actually succeeded. Once its visibility timeout
expires, it redelivers the same message. A second worker (or the same one
after restart) picks it up and reprocesses it from scratch: the side
effect runs twice.

This is not a corner case, it's the default behavior of any at-least-once
queue (SQS, most brokers built on visibility timeouts / ack deadlines). The
guarantee a queue gives you is "delivered at least once," not "executed at
most once" — those are two different problems, and the gap between them is
exactly where double-charges, duplicate emails, and double-writes come
from.

## Failure scenario reproduced in this repo

1. A job to charge `order-42` $50.00 is enqueued.
2. A worker polls it, calls the payment side effect (charge succeeds), and
   then — simulating a crash or dropped ack — never tells the broker.
3. The broker's visibility timeout expires and redelivers the same
   message.
4. A worker polls it again and, with no protection in place, charges it a
   second time.

`NaiveWorker` in `workers.py` reproduces this exactly: `test_duplicate_execution.py::test_ack_loss_causes_double_charge` asserts the charge count comes out to **2**.

## The fix

`IdempotentWorker` adds one thing between "poll" and "run the side effect":

1. **Idempotency key per job**, generated at enqueue time and carried with
   the message (not derived from delivery attempt, so every redelivery of
   the same job carries the same key).
2. **A dedup ledger** (`dedup.py`) tracking each key as `in_progress` /
   `done`, with the stored result for `done` keys.
3. **Atomic claim before execution.** `try_claim(key)` is the only way to
   get permission to run the side effect. A redelivered copy either finds
   the key already `done` (skips execution, would replay the stored
   result) or already `in_progress` (backs off) — so two redelivered
   copies of the same job can never both execute, including when they
   race concurrently (`test_only_one_concurrent_claimant_wins` fires 20
   threads at the same key simultaneously and asserts exactly one wins).
4. **TTL-bounded ledger.** Completed entries expire after `ttl_seconds` so
   the store doesn't grow without limit — the dedup equivalent of a
   mailbox/overflow limit on the queue itself.

`test_ack_loss_does_not_double_charge` reruns the identical failure
scenario against `IdempotentWorker` and asserts the charge count comes out
to **1**.

## How this maps to real systems

- SQS: exactly this trade-off is why AWS ships `MessageDeduplicationId` on
  FIFO queues and recommends idempotent consumers for standard queues.
- Kafka: idempotent producers dedupe on `(producer ID, sequence number)`
  on the write side; consumers still need the same pattern here on the
  processing side for at-least-once delivery.
- Stripe / most payment APIs: client-supplied `Idempotency-Key` headers
  are this exact pattern pushed to the API boundary.

## Running it

```
cd exactly-once-queue

# see the bug, then see the fix, side by side
python demo.py naive
python demo.py idempotent

# prove both with tests
python -m unittest -v
# or: pytest -v
```

## Layout

| File | Role |
|---|---|
| `broker.py` | At-least-once queue with visibility-timeout redelivery |
| `dedup.py` | Idempotency ledger: atomic claim + TTL-bounded completion cache |
| `side_effects.py` | A non-idempotent side effect (payment charge) to observe duplication on |
| `workers.py` | `NaiveWorker` (has the bug) and `IdempotentWorker` (has the fix) |
| `demo.py` | CLI to watch both modes run against the same scenario |
| `test_duplicate_execution.py` | Proves the bug, proves the fix, proves the concurrent-claim race is closed |
