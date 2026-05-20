CREATE TABLE IF NOT EXISTS shared.events_hybrid_writer
(
    event_time DateTime,
    user_id    UInt64,
    event_type LowCardinality(String),
    payload    String
)
ENGINE = MergeTree()
PARTITION BY toYYYYMM(event_time)
ORDER BY (event_time, user_id, event_type)
TTL event_time + INTERVAL 1 MONTH TO VOLUME 'cold'
SETTINGS storage_policy = 'hybrid_local_s3';

CREATE TABLE IF NOT EXISTS shared.events_hybrid_shared_s3
(
    event_time DateTime,
    user_id    UInt64,
    event_type String,
    payload    String
)
ENGINE = S3(
    'http://minio:9000/ch-shared/shared-exchange/events_hybrid_shared.ndjson',
    'writer',
    'writer-secret',
    'JSONEachRow'
);

CREATE MATERIALIZED VIEW IF NOT EXISTS shared.mv_events_hybrid_writer_to_shared_s3
TO shared.events_hybrid_shared_s3
AS
SELECT event_time, user_id, event_type, payload
FROM shared.events_hybrid_writer;
