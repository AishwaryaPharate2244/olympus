"""A side effect that is NOT naturally idempotent, standing in for things
like charging a card or sending an email -- the reason duplicate execution
is dangerous rather than merely wasteful.
"""
import threading


class PaymentLedger:
    def __init__(self) -> None:
        self._lock = threading.Lock()
        self.charges: list[tuple[str, int]] = []

    def charge(self, order_id: str, amount_cents: int) -> str:
        with self._lock:
            self.charges.append((order_id, amount_cents))
            return f"charge-{len(self.charges)}"

    def total_charged(self, order_id: str) -> int:
        with self._lock:
            return sum(amount for oid, amount in self.charges if oid == order_id)

    def charge_count(self, order_id: str) -> int:
        with self._lock:
            return sum(1 for oid, _ in self.charges if oid == order_id)
