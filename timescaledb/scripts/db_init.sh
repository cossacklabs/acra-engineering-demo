#!/usr/bin/env bash

set -euo pipefail

echo 'Waiting for DB...'
while ! pg_isready -h $POSTGRES_HOST -p $POSTGRES_PORT -d $POSTGRES_DB; do
    sleep 1
done

echo 'Creating structure...'
psql $POSTGRESQL_CONNSTR <<'EOF'
CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;
EOF

psql $POSTGRESQL_CONNSTR <<'EOF'
CREATE TABLE cpu_temp (
  ts                    TIMESTAMPTZ NOT NULL,
  device                BYTEA NOT NULL,
  unit_id               BYTEA NOT NULL,
  temp                  DOUBLE PRECISION NOT NULL
);
EOF

psql $POSTGRESQL_CONNSTR <<'EOF'
SELECT create_hypertable('cpu_temp', 'ts', chunk_time_interval => interval '1 day');
EOF
