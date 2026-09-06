"""Run with: python demo.py naive | python demo.py idempotent"""
import sys
import uuid

from broker import Broker
from dedup import IdempotencyStore
from side_effects import PaymentLedger
from workers import IdempotentWorker, NaiveWorker


def run(mode: str) -> None:
    broker = Broker()
    ledger = PaymentLedger()
    order_id = "order-42"
    job = {
        "order_id": order_id,
        "amount_cents": 5000,
        "idempotency_key": str(uuid.uuid4()),
    }
    message_id = broker.enqueue(job)

    if mode == "naive":
        worker = NaiveWorker(broker, ledger)
    elif mode == "idempotent":
        worker = IdempotentWorker(broker, ledger, IdempotencyStore())
    else:
        raise SystemExit("mode must be 'naive' or 'idempotent'")

    print(f"--- mode: {mode} ---")
    worker.process_available_but_lose_ack()
    print(f"[1st delivery]     charges so far: {ledger.charge_count(order_id)}")

    broker.expire_visibility(message_id)  # ack never arrived -> redelivered
    worker.process_available()
    print(f"[after redelivery] charges so far: {ledger.charge_count(order_id)}")
    print(f"total charged: ${ledger.total_charged(order_id) / 100:.2f} (should be $50.00)")


if __name__ == "__main__":
    run(sys.argv[1] if len(sys.argv) > 1 else "naive")
