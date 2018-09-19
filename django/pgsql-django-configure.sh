#!/usr/bin/env bash

set -Eeuo pipefail

for name in djangoproject code.djangoproject; do
    psql -v ON_ERROR_STOP=1 --username postgres <<EOSQL
CREATE USER "$name" WITH NOSUPERUSER NOCREATEDB NOCREATEROLE PASSWORD '$POSTGRES_DJANGO_PASSWORD' ;
CREATE DATABASE "$name" OWNER "$name" ;
EOSQL
done
