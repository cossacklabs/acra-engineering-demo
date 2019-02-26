#!/bin/bash

export POSTGRESQL_CONNSTR="postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}"\
"@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}?sslmode=disable"

/scripts/db_init.sh
/scripts/db_fill.sh

/scripts/db_add_value_daemon.sh
