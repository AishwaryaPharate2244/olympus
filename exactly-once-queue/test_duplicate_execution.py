"""Proves the bug under NaiveWorker and proves it closed under
IdempotentWorker, using one failure scenario: a job is processed, its ack
is lost, and the broker redelivers it.
"""
import threading
import unittest
import uuid

from broker import Broker
from dedup import IdempotencyStore
from side_effects import PaymentLedger
from workers import IdempotentWorker, NaiveWorker


def make_job(order_id: str = "order-1", amount_cents: int = 5000) -> dict:
    return {
        "order_id": order_id,
        "amount_cents": amount_cents,
        "idempotency_key": str(uuid.uuid4()),
    }


class NaiveWorkerDuplicatesOnRedelivery(unittest.TestCase):
    def test_ack_loss_causes_double_charge(self):
        broker = Broker()
        ledger = PaymentLedger()
        worker = NaiveWorker(broker, ledger)
        job = make_job()
        message_id = broker.enqueue(job)

        worker.process_available_but_lose_ack()
        broker.expire_visibility(message_id)
        worker.process_available()

        self.assertEqual(ledger.charge_count(job["order_id"]), 2)  # the bug


class IdempotentWorkerDedupesOnRedelivery(unittest.TestCase):
    def test_ack_loss_does_not_double_charge(self):
        broker = Broker()
        ledger = PaymentLedger()
        worker = IdempotentWorker(broker, ledger, IdempotencyStore())
        job = make_job()
        message_id = broker.enqueue(job)

        worker.process_available_but_lose_ack()
        broker.expire_visibility(message_id)
        worker.process_available()

        self.assertEqual(ledger.charge_count(job["order_id"]), 1)  # fixed


class IdempotencyStoreConcurrencyTest(unittest.TestCase):
    def test_only_one_concurrent_claimant_wins(self):
        """The harder race: many redelivery attempts on the same key at the
        same instant. The atomic claim -- not the broker -- has to be what
        prevents concurrent double execution."""
        store = IdempotencyStore()
        key = "shared-key"
        results: list[bool] = []
        results_lock = threading.Lock()
        barrier = threading.Barrier(20)

        def attempt():
            barrier.wait()
            claimed = store.try_claim(key)
            with results_lock:
                results.append(claimed)

        threads = [threading.Thread(target=attempt) for _ in range(20)]
        for t in threads:
            t.start()
        for t in threads:
            t.join()

        self.assertEqual(results.count(True), 1)
        self.assertEqual(results.count(False), 19)


if __name__ == "__main__":
    unittest.main()
