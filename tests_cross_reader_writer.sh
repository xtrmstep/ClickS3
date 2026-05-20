#!/usr/bin/env bash
set -euo pipefail

writer="docker exec ch-writer clickhouse-client -u default --password clickhouse -q"
reader="docker exec ch-reader clickhouse-client -u default --password clickhouse -q"

$writer "TRUNCATE TABLE shared.events_hybrid_writer"
$writer "INSERT INTO shared.events_hybrid_writer VALUES (now(), 101, 'signup', '{\"source\":\"test\"}'), (now(), 102, 'purchase', '{\"source\":\"test\"}')"

# give MV/S3 write a brief moment
sleep 1

writer_count=$($writer "SELECT count() FROM shared.events_hybrid_shared_s3")
reader_count=$($reader "SELECT count() FROM shared.events_hybrid_shared_s3")

if [[ "$writer_count" != "$reader_count" ]]; then
  echo "count mismatch writer=$writer_count reader=$reader_count"
  exit 1
fi

if [[ "$reader_count" -lt 2 ]]; then
  echo "expected at least 2 rows in reader, got $reader_count"
  exit 1
fi

echo "PASS writer_count=$writer_count reader_count=$reader_count"
