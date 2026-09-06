"""Idempotency ledger that makes a redelivered job safe to reprocess.

A key is claimed atomically before its side effect runs; a redelivered
copy of the same job either finds it already "done" (and replays instead
of re-executes) or already "in_progress" (and backs off).
"""
import threading
import time
from dataclasses import dataclass
from typing import Any, Optional


@dataclass
class _Entry:
    state: str  # "in_progress" | "done"
    result: Any = None
    expires_at: float = 0.0


class IdempotencyStore:
    """Bounded by TTL so the ledger doesn't grow without limit."""

    def __init__(self, ttl_seconds: float = 300.0) -> None:
        self._lock = threading.Lock()
        self._entries: dict[str, _Entry] = {}
        self._ttl = ttl_seconds

    def try_claim(self, key: str) -> bool:
        now = time.monotonic()
        with self._lock:
            entry = self._entries.get(key)
            if entry is not None and entry.state == "done" and entry.expires_at > now:
                return False
            if entry is not None and entry.state == "in_progress":
                return False
            self._entries[key] = _Entry(state="in_progress")
            return True

    def mark_done(self, key: str, result: Any) -> None:
        with self._lock:
            self._entries[key] = _Entry(
                state="done", result=result, expires_at=time.monotonic() + self._ttl
            )

    def result_of(self, key: str) -> Optional[Any]:
        with self._lock:
            entry = self._entries.get(key)
            return entry.result if entry and entry.state == "done" else None

    def evict_expired(self) -> None:
        now = time.monotonic()
        with self._lock:
            expired = [
                k for k, e in self._entries.items()
                if e.state == "done" and e.expires_at <= now
            ]
            for k in expired:
                del self._entries[k]
