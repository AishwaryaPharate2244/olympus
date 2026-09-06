"""Minimal in-memory broker with SQS-style visibility timeouts.

A message becomes invisible when polled and reappears if it isn't acked
before the timeout expires. That redelivery-on-timeout contract is exactly
what turns a lost ack into a duplicate delivery.
"""
import itertools
import threading
import time
from dataclasses import dataclass
from typing import Any, Optional


@dataclass
class _Message:
    id: str
    body: Any
    visible_at: float
    delivery_count: int = 0


class Broker:
    def __init__(self) -> None:
        self._lock = threading.Lock()
        self._messages: dict[str, _Message] = {}
        self._ids = itertools.count(1)

    def enqueue(self, body: Any) -> str:
        message_id = f"msg-{next(self._ids)}"
        with self._lock:
            self._messages[message_id] = _Message(message_id, body, visible_at=0.0)
        return message_id

    def poll(self, visibility_timeout: float = 30.0) -> Optional[tuple[str, Any]]:
        now = time.monotonic()
        with self._lock:
            for message in self._messages.values():
                if message.visible_at <= now:
                    message.visible_at = now + visibility_timeout
                    message.delivery_count += 1
                    return message.id, message.body
        return None

    def ack(self, message_id: str) -> None:
        with self._lock:
            self._messages.pop(message_id, None)

    def expire_visibility(self, message_id: str) -> None:
        """Test hook standing in for a visibility-timeout expiry or a
        dropped ack: makes the message immediately redeliverable."""
        with self._lock:
            if message_id in self._messages:
                self._messages[message_id].visible_at = 0.0

    def delivery_count(self, message_id: str) -> int:
        with self._lock:
            return self._messages[message_id].delivery_count
