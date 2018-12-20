#!/usr/bin/env bash

set -Eeuo pipefail

# SUPERUSER is required to perform `CREATE EXTENSION` query
for name in djangoproject code.djangoproject; do
    psql -v ON_ERROR_STOP=1 --username postgres <<EOSQL
CREATE USER "$name" WITH SUPERUSER NOCREATEDB NOCREATEROLE PASSWORD '$POSTGRES_DJANGO_PASSWORD' ;
CREATE DATABASE "$name" OWNER "$name" ;
EOSQL
done
