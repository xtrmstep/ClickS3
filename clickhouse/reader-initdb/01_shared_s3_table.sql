CREATE DATABASE IF NOT EXISTS shared;

CREATE TABLE IF NOT EXISTS shared.events_shared_s3
(
    event_time DateTime,
    user_id    UInt64,
    event_type String,
    payload    String
)
ENGINE = S3(
    'http://minio:9000/ch-shared/shared-exchange/events_shared_s3.ndjson',
    'reader',
    'reader-secret',
    'JSONEachRow'
);
