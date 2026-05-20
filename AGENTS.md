# Agent Instructions

## Concepts

**ClickHouse with S3 storage** — ClickHouse is configured with a custom storage policy (`s3_main`) that stores all MergeTree data in MinIO instead of local disk. This gives compute/storage separation: ClickHouse is stateless and data persists independently.

**Kafka ingestion** — Events are produced to Kafka topic `events_stream`. ClickHouse reads them via a Kafka engine table (`events_kafka_queue`) and two materialized views fan the data into persistent S3-backed tables.

**MinIO as S3** — MinIO is the local S3 replacement. The bucket `ch-shared` holds all ClickHouse data files. IAM-style policies control access (separate `writer` and `reader` credentials can be added if needed).

## Repository structure

```
docker-compose.yml          # All services: minio, kafka, clickhouse, producer tooling
clickhouse/
  config.d/
    s3.xml                  # S3 storage policy and disk definition
    docker_related_config.xml
  initdb/
    01_create_tables.sql    # shared.events table (MergeTree on S3)
    02_kafka_tables.sql     # Kafka engine table + materialized views + target tables
minio/
  policies/
    writer-policy.json      # Read/write access to ch-shared/*
    reader-policy.json      # Read-only access to ch-shared/*
producer/
  produce.py                # Python script that sends JSON events to Kafka
  pyproject.toml
```

## Key tables (database `shared`)

| Table | Engine | Purpose |
|---|---|---|
| `events` | MergeTree (S3) | Seed data, inserted at init |
| `events_kafka_queue` | Kafka | Reads from `events_stream` topic |
| `events_raw` | MergeTree (S3) | Raw copy of every Kafka event |
| `events_by_type` | SummingMergeTree (S3) | Event counts aggregated by type |

## Guidelines for agents

- Do not change the S3 storage policy name `s3_main`; it is referenced in all `CREATE TABLE` statements.
- MinIO credentials are defined in `docker-compose.yml` and referenced in `clickhouse/config.d/s3.xml` — keep them in sync.
- SQL init scripts run in lexicographic order (`01_` before `02_`). Add new scripts with the next prefix.
- The producer sends `JSONEachRow` format matching the schema in `02_kafka_tables.sql`.
