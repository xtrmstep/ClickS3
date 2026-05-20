CREATE DATABASE IF NOT EXISTS shared;

CREATE TABLE IF NOT EXISTS shared.events
(
    event_time DateTime,
    user_id    UInt64,
    action     String
)
ENGINE = MergeTree()
ORDER BY (event_time, user_id)
SETTINGS storage_policy = 's3_main';

INSERT INTO shared.events VALUES
('2026-01-01 00:00:00', 1, 'signup'),
('2026-01-01 00:05:00', 2, 'login'),
('2026-01-01 00:10:00', 1, 'purchase');
