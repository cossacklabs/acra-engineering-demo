#!/usr/bin/env bash

set -Eeuo pipefail

for f in root.crt server.crt server.key; do
    cp /tmp.ssl/${f} "${PGDATA}/"
    chown postgres:postgres "${PGDATA}/${f}"
    chmod 0600 "${PGDATA}/${f}"
done

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
set_pg_option "$PGDATA/postgresql.conf" "listen_addresses" "'*'"
set_pg_option "$PGDATA/postgresql.conf" "ssl" "on"
set_pg_option "$PGDATA/postgresql.conf" "ssl_ca_file" "'root.crt'"
set_pg_option "$PGDATA/postgresql.conf" "ssl_cert_file" "'server.crt'"
set_pg_option "$PGDATA/postgresql.conf" "ssl_key_file" "'server.key'"

# SUPERUSER is required to perform `CREATE EXTENSION` query
for name in djangoproject code.djangoproject; do
    psql -v ON_ERROR_STOP=1 --username postgres <<EOSQL
CREATE USER "$name" WITH SUPERUSER NOCREATEDB NOCREATEROLE PASSWORD '$POSTGRES_DJANGO_PASSWORD' ;
CREATE DATABASE "$name" OWNER "$name" ;
EOSQL
done
