#!/usr/bin/env bash

set -euo pipefail

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

set_pg_option /usr/share/postgresql/11/extension/pg_trgm.control superuser false
set_pg_option "$PGDATA/postgresql.conf" log_statement all
