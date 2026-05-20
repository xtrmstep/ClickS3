# Producer

Sends random events (`click`, `view`, `purchase`, `signup`, etc.) to Kafka topic `events_stream` on `localhost:9094`. Each message is a JSON row matching the `shared.events_raw` schema.

## Usage

```
uv run produce.py <count> <interval_ms>
```

`interval_ms` controls the delay between messages:

| Value | Behaviour |
|---|---|
| `0` | No delay — send all at once |
| `200` | Fixed 200 ms between messages |
| `100-500` | Random delay between 100 and 500 ms |

## Examples

```bash
cd producer

# 20 messages, random 100–500 ms gap
uv run produce.py 20 100-500

# 50 messages, fixed 200 ms gap
uv run produce.py 50 200

# 100 messages, no delay
uv run produce.py 100 0
```

`uv` handles the virtual environment automatically — no manual install step needed.
