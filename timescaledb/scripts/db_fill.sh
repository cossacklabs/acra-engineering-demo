#!/usr/bin/env bash

set -euo pipefail

echo 'Filling with random data...'
TMP_SQL=/tmp/tmp_$(date +%Y%m%d%H%M%S).sql
DATE_EPOCH_BASE=$(date +%s)
for i in {0..600}
do
    DEVICE='ABCDEF'$(($RANDOM % 4))
    UNIT_ID=$(($RANDOM % 10))
    DATE=$(date -d @$((DATE_EPOCH_BASE - i * 2)) +'%Y-%m-%d %H:%M:%S%z')
    echo "INSERT INTO cpu_temp(ts, device, unit_id, temp) VALUES ('$DATE', '$DEVICE', '$UNIT_ID', $RANDOM / 2500 + 25);" >> $TMP_SQL
done

psql $POSTGRESQL_CONNSTR < $TMP_SQL

rm -f $TMP_SQL
