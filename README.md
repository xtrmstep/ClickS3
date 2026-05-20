# ClickS3

ClickHouse stores all data in MinIO (S3-compatible). Kafka streams events into ClickHouse via materialized views. A Python producer sends test messages.

## Services

| Service | Purpose |
|---|---|
| `minio` | S3-compatible object storage, bucket `ch-shared` |
| `mc-init` | Creates bucket, users, and policies on startup |
| `kafka` | Event stream broker, topic `events_stream` |
| `kafka-ui` | Kafka web UI at `localhost:8080` |
| `ch-writer` | Writer ClickHouse node (Kafka + hybrid writer table) |
| `ch-reader` | Reader ClickHouse node (read-only view over shared S3 dataset) |

## Key concepts

- **Storage in S3** — ClickHouse uses `s3_main` storage policy. All table data lives in MinIO, not on local disk.
- **Kafka ingestion** — `events_kafka_queue` is a Kafka engine table. Two materialized views fan out incoming messages to `events_raw` (raw rows) and `events_by_type` (aggregated counts).
- **Separation of compute and storage** — ClickHouse is stateless; you can restart or scale it without losing data.
- **Hybrid tiering option** — `shared.events_hybrid` keeps recent monthly partition(s) on local disk and moves older data to S3 with TTL. See `clickhouse/initdb/04_hybrid_partition_ops.md` for manual partition movement commands.

## Run

```bash
docker compose up -d
```

Wait for all services to be healthy, then query:

```bash
# raw events
docker exec -it ch-writer clickhouse-client -u default --password clickhouse \
  -q "SELECT * FROM shared.events ORDER BY event_time"

# aggregated counts from Kafka stream
docker exec -it ch-writer clickhouse-client -u default --password clickhouse \
  -q "SELECT * FROM shared.events_by_type"
```

Send test events via the producer:

```bash
cd producer && uv run produce.py
```


## Writer/reader shared S3 test

Run the cross-node visibility test:

```bash
./tests_cross_reader_writer.sh
```

This test inserts into `shared.events_hybrid_writer` on `ch-writer` and asserts the same row count is visible through `shared.events_hybrid_shared_s3` on `ch-reader`.
