#!/bin/bash

export PGSSLCERT=/scripts/acra-client.crt
export PGSSLKEY=/scripts/acra-client.key
export PGSSLROOTCERT=/scripts/ca.crt
export PGSSLMODE=verify-full
export PGUSER=${POSTGRES_USER:-postgres}
export POSTGRESQL_CONNSTR="postgres://${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}"

/scripts/db_init.sh
/scripts/db_fill.sh

/scripts/db_add_value_daemon.sh
