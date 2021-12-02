#!/usr/bin/env bash

set -Eeuo pipefail

echo 'Waiting for PostgreSQL...'
while ! pg_isready -h $POSTGRES_HOST -p 5432; do
    sleep 1
done

# Create DB scheme
PSQL_CONNSTR="postgresql://$POSTGRES_USER:$POSTGRES_PASSWORD@"\
"$POSTGRES_HOST:5432/code.djangoproject?sslcert=/app/blog/ssl/acra-client.crt"\
"&sslkey=/app/blog/ssl/acra-client.key"\
"&sslrootcert=/app/blog/ssl/root.crt"\
"&sslmode=verify-full"

/usr/bin/psql $PSQL_CONNSTR < tracdb/trac.sql

ACRA_PUB_KEY_PATH=$(find "$PUBLIC_KEY_DIR" -type f -name \*.pub -print)
ACRA_STORAGE_PUBKEY=$(cat "$ACRA_PUB_KEY_PATH" | base64)


cat > $DJANGOPROJECT_DATA_DIR/conf/secrets.json <<EOF
{
  "secret_key": "$(dd if=/dev/urandom bs=4 count=16 2>/dev/null | base64 | head -c 32)",
  "superfeedr_creds": ["email@example.com", "some_string"],
  "db_host": "$ACRA_SERVER_HOST",
  "db_port": "$ACRA_SERVER_PORT",
  "db_password": "$POSTGRES_DJANGO_PASSWORD",
  "trac_db_host": "$ACRA_SERVER_HOST",
  "trac_db_password": "$POSTGRES_DJANGO_PASSWORD",
  "trac_db_port": "$ACRA_SERVER_PORT",
  "acra_storage_public_key": "$ACRA_STORAGE_PUBKEY"
}
EOF


/app/manage.py migrate
python3 /app/manage.py shell <<EOF
from django.contrib.auth.models import User
if not User.objects.filter(username='${DJANGO_ADMIN_LOGIN}').count():
    User.objects.create_superuser('${DJANGO_ADMIN_LOGIN}', 'email@example.com', '${DJANGO_ADMIN_PASSWORD}')

EOF
/app/manage.py loaddata dev_sites
/app/manage.py loaddata dashboard_production_metrics
/app/manage.py update_metrics

cd /app
make compile-scss

exec make run
