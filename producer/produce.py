#!/usr/bin/env python3
"""
Produce random events to Kafka topic 'events_stream'.

Usage:
    uv run produce.py <count> <interval_ms>

interval_ms examples:
    0        — no delay, send all messages immediately
    500      — fixed 500 ms between messages
    100-500  — random delay between 100 and 500 ms

Run once to set up the venv (UV does this automatically):
    cd producer && uv run produce.py 10 100-500
"""

import json
import random
import sys
import time
from datetime import datetime

from confluent_kafka import Producer

BOOTSTRAP_SERVERS = "localhost:9094"
TOPIC = "events_stream"

EVENT_TYPES = ["click", "view", "purchase", "signup", "logout", "search", "add_to_cart"]


def parse_interval(arg: str) -> tuple[int, int]:
    """Parse interval argument into (min_ms, max_ms)."""
    if "-" in arg:
        lo, hi = arg.split("-", 1)
        return int(lo), int(hi)
    val = int(arg)
    return val, val


def random_event() -> dict:
    return {
        "event_time": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "user_id": random.randint(1, 1000),
        "event_type": random.choice(EVENT_TYPES),
        "event_data": "{}",
    }


def delay_between(min_ms: int, max_ms: int) -> None:
    if min_ms == 0:
        return
    ms = random.randint(min_ms, max_ms) if min_ms != max_ms else min_ms
    time.sleep(ms / 1000)


def main():
    if len(sys.argv) != 3:
        print("Usage: produce.py <count> <interval_ms>")
        print("  interval_ms: 0 | 500 | 100-500")
        sys.exit(1)

    count = int(sys.argv[1])
    min_ms, max_ms = parse_interval(sys.argv[2])

    producer = Producer({"bootstrap.servers": BOOTSTRAP_SERVERS})

    for i in range(count):
        event = random_event()
        producer.produce(TOPIC, value=json.dumps(event))
        producer.poll(0)
        print(f"[{i + 1}/{count}] {event['event_type']:12s}  user={event['user_id']}")
        if i < count - 1:
            delay_between(min_ms, max_ms)

    producer.flush()
    print(f"\nDone. Sent {count} messages to '{TOPIC}'.")


if __name__ == "__main__":
    main()
