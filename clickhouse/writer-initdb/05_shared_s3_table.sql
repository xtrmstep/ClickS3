CREATE TABLE IF NOT EXISTS shared.events_shared_s3
(
    event_time DateTime,
    user_id    UInt64,
    event_type String,
    payload    String
)
ENGINE = MergeTree()
ORDER BY (event_time, user_id, event_type)
SETTINGS storage_policy = 's3_main';
