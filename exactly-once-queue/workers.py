"""Two workers pulling from the same broker: one naive, one idempotent.
Both are exercised against the identical failure scenario in the tests
and in demo.py to show the before/after contrast directly.
"""
from typing import Optional

from broker import Broker
from dedup import IdempotencyStore
from side_effects import PaymentLedger


class NaiveWorker:
    """Processes a job then acks -- no protection against redelivery."""

    def __init__(self, broker: Broker, ledger: PaymentLedger) -> None:
        self.broker = broker
        self.ledger = ledger

    def process_available(self) -> Optional[str]:
        polled = self.broker.poll()
        if polled is None:
            return None
        message_id, job = polled
        self.ledger.charge(job["order_id"], job["amount_cents"])
        self.broker.ack(message_id)
        return message_id

    def process_available_but_lose_ack(self) -> Optional[str]:
        """Simulates a crash/network drop between finishing the side effect
        and the ack reaching the broker -- the actual trigger for the bug."""
        polled = self.broker.poll()
        if polled is None:
            return None
        message_id, job = polled
        self.ledger.charge(job["order_id"], job["amount_cents"])
        return message_id


class IdempotentWorker:
    """Same broker, same side effect -- but claims an idempotency key before
    executing, so a redelivered job replays the prior outcome instead of
    re-running it."""

    def __init__(self, broker: Broker, ledger: PaymentLedger, store: IdempotencyStore) -> None:
        self.broker = broker
        self.ledger = ledger
        self.store = store

    def process_available(self) -> Optional[str]:
        polled = self.broker.poll()
        if polled is None:
            return None
        message_id, job = polled
        key = job["idempotency_key"]
        if self.store.try_claim(key):
            result = self.ledger.charge(job["order_id"], job["amount_cents"])
            self.store.mark_done(key, result)
        self.broker.ack(message_id)
        return message_id

    def process_available_but_lose_ack(self) -> Optional[str]:
        polled = self.broker.poll()
        if polled is None:
            return None
        message_id, job = polled
        key = job["idempotency_key"]
        if self.store.try_claim(key):
            result = self.ledger.charge(job["order_id"], job["amount_cents"])
            self.store.mark_done(key, result)
        return message_id
