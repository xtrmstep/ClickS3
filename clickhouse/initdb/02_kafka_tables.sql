-- ============================================================
-- Kafka source table (not persistent — acts as a message queue)
-- Messages are expected as JSON:
--   {"event_time":"2026-01-01 00:00:00","user_id":1,"event_type":"click","event_data":"{}"}
-- ============================================================
CREATE TABLE IF NOT EXISTS shared.events_kafka_queue
(
    event_time DateTime,
    user_id    UInt64,
    event_type String,
    event_data String
)
ENGINE = Kafka
SETTINGS
    kafka_broker_list = 'kafka:9092',
    kafka_topic_list  = 'events_stream',
    kafka_group_name  = 'clickhouse_consumer_group',
    kafka_format      = 'JSONEachRow';

-- ============================================================
-- Target table 1: aggregated event counts by type
-- SummingMergeTree merges rows with the same event_type by
-- summing event_count, so each type collapses to one record.
-- ============================================================
CREATE TABLE IF NOT EXISTS shared.events_by_type
(
    event_type  String,
    event_count UInt64
)
ENGINE = SummingMergeTree()
ORDER BY event_type
SETTINGS storage_policy = 's3_main';

-- Materialized View 1: groups each incoming batch by event_type
-- and inserts the per-type counts into events_by_type.
CREATE MATERIALIZED VIEW IF NOT EXISTS shared.mv_events_by_type
TO shared.events_by_type
AS
SELECT
    event_type,
    count() AS event_count
FROM shared.events_kafka_queue
GROUP BY event_type;

-- ============================================================
-- Target table 2: all raw events, one row per message
-- ============================================================
CREATE TABLE IF NOT EXISTS shared.events_raw
(
    event_time DateTime,
    user_id    UInt64,
    event_type String,
    event_data String
)
ENGINE = MergeTree()
ORDER BY (event_time, user_id)
SETTINGS storage_policy = 's3_main';

-- Materialized View 2: copies every arriving event as-is
CREATE MATERIALIZED VIEW IF NOT EXISTS shared.mv_events_raw
TO shared.events_raw
AS
SELECT event_time, user_id, event_type, event_data
FROM shared.events_kafka_queue;
