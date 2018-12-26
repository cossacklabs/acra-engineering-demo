#!/usr/bin/env bash

set -Eeuo pipefail

set_pg_option() {
    local PG_CONFFILE="$1"
    local OPTION="$2"
    local VALUE="$3"
    if grep -q "$OPTION" "$PG_CONFFILE"; then
        sed -i "s/^#*${OPTION}\\s*=.*/${OPTION} = ${VALUE}/g" "$PG_CONFFILE"
    else
        echo "${OPTION} = ${VALUE}" >> "$PG_CONFFILE"
    fi
}

set_pg_option "$PGDATA/postgresql.conf" log_statement all

# SUPERUSER is required to perform `CREATE EXTENSION` query
for name in djangoproject code.djangoproject; do
    psql -v ON_ERROR_STOP=1 --username postgres <<EOSQL
CREATE USER "$name" WITH SUPERUSER NOCREATEDB NOCREATEROLE PASSWORD '$POSTGRES_DJANGO_PASSWORD' ;
CREATE DATABASE "$name" OWNER "$name" ;
EOSQL
done
