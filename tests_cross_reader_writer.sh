#!/usr/bin/env bash
set -euo pipefail

writer="docker exec ch-writer clickhouse-client -u default --password clickhouse -q"
reader="docker exec ch-reader clickhouse-client -u default --password clickhouse -q"

$writer "INSERT INTO shared.events_shared_s3 VALUES (now(), 101, 'signup', '{\"source\":\"test\"}'), (now(), 102, 'purchase', '{\"source\":\"test\"}')"

writer_count=$($writer "SELECT count() FROM shared.events_shared_s3")
reader_count=$($reader "SELECT count() FROM shared.events_shared_s3")

if [[ "$writer_count" != "$reader_count" ]]; then
  echo "count mismatch writer=$writer_count reader=$reader_count"
  exit 1
fi

echo "PASS writer_count=$writer_count reader_count=$reader_count"
