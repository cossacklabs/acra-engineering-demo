#!/usr/bin/env bash

set -u

while true
do
    DATE=$(date +'%Y-%m-%d %H:%M:%S%z')
    DEVICE='ABCDEF'$(($RANDOM % 4))
    UNIT_ID=$(($RANDOM % 10))

    psql $POSTGRESQL_CONNSTR <<EOF
INSERT INTO cpu_temp(ts, device, unit_id, temp) VALUES ('$DATE', '$DEVICE', '$UNIT_ID', $RANDOM / 2500 + 25);
EOF
    sleep 2
done
