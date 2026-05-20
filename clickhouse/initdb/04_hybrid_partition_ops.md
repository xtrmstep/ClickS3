# Hybrid partition operations (local disk + S3)

The table `shared.events_hybrid` uses:

- Monthly partitions: `PARTITION BY toYYYYMM(event_time)`
- Hybrid storage policy: `hybrid_local_s3`
- Automatic movement rule: rows older than 1 month move to volume `cold` (S3)

## Verify where partitions are stored

Insert data into the table and check partition locations:

```sql
INSERT INTO shared.events_hybrid (event_time, user_id, event_type, payload) VALUES
(current_timestamp(), 1, 'close', 'data'),
(current_timestamp() - toIntervalDay(5), 2, 'close', 'data'),
(current_timestamp() - toIntervalDay(15), 3, 'close', 'data'),
(current_timestamp() - toIntervalMonth(2), 4, 'close', 'data'),
(current_timestamp() - toIntervalMonth(3), 5, 'close', 'data');
```

```sql
SELECT
    partition,
    disk_name,
    sum(rows) AS rows,
    formatReadableSize(sum(bytes_on_disk)) AS size
FROM system.parts
WHERE database = 'shared'
  AND table = 'events_hybrid'
  AND active
GROUP BY partition, disk_name
ORDER BY partition, disk_name;
```

Expected behavior:

- Current month partition is usually on `default` (local disk)
- Older partitions are moved to `s3_disk`

## Move a partition from local disk to S3 manually

Use this when you want to force movement before TTL executes.

```sql
ALTER TABLE shared.events_hybrid
    MOVE PARTITION 202601 TO VOLUME 'cold';
```

You can also move directly to the S3 disk:

```sql
ALTER TABLE shared.events_hybrid
    MOVE PARTITION 202601 TO DISK 's3_disk';
```

## Move a partition back to local disk

```sql
ALTER TABLE shared.events_hybrid
    MOVE PARTITION 202601 TO VOLUME 'hot';
```

## Notes

- `MOVE PARTITION` is metadata-aware and relocates active parts for that partition.
- Partitions are represented by `toYYYYMM(event_time)` values like `202601`.
- Keep one hot partition locally by moving older partitions to `cold` on a schedule (or rely on TTL).
