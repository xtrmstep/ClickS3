-- ============================================================
-- Hybrid storage table:
-- - Monthly partitions by event_time
-- - New data is written to local disk first
-- - Data older than 1 month is moved to S3 volume automatically
-- ============================================================
CREATE TABLE IF NOT EXISTS shared.events_hybrid
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
