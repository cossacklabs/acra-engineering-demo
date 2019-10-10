entry.sh

#!/usr/bin/env bash

set -Eeuo pipefail

mkdir -p $DJANGOPROJECT_DATA_DIR/conf

cat > $DJANGOPROJECT_DATA_DIR/conf/secrets.json <<EOF
{
  "secret_key": "$(dd if=/dev/urandom bs=4 count=16 2>/dev/null | base64 | head -c 32)",
  "superfeedr_creds": ["email@example.com", "some_string"],
  "db_host": "$ACRA_HOST",
  "db_password": "$POSTGRES_DJANGO_PASSWORD",
  "db_port": "$ACRA_PORT",
  "trac_db_host": "$ACRA_HOST",
  "trac_db_password": "$POSTGRES_DJANGO_PASSWORD",
  "trac_db_port": "$ACRA_PORT",
  "allowed_hosts": ["$DJANGO_HOST", "www.$DJANGO_HOST"],
  "parent_host": "$DJANGO_HOST:8000"
}
EOF
