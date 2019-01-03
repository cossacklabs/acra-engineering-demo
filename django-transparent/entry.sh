#!/usr/bin/env bash

set -Eeuo pipefail

cat > $DJANGOPROJECT_DATA_DIR/conf/secrets.json <<EOF
{
  "secret_key": "$(dd if=/dev/urandom bs=4 count=16 2>/dev/null | base64 | head -c 32)",
  "superfeedr_creds": ["email@example.com", "some_string"],
  "db_host": "$POSTGRES_HOST",
  "db_password": "$POSTGRES_DJANGO_PASSWORD",
  "trac_db_host": "$POSTGRES_HOST",
  "trac_db_password": "$POSTGRES_DJANGO_PASSWORD"
}
EOF

export PGSSLMODE=disable

echo 'Waiting for PostgreSQL...'
while ! pg_isready -h $POSTGRES_HOST -p 5432; do
    sleep 1
done

# Create DB scheme
PSQL_CONNSTR="postgresql://$POSTGRES_USER:$POSTGRES_PASSWORD@"\
"$POSTGRES_HOST:5432/code.djangoproject?sslmode=disable"
/usr/bin/psql $PSQL_CONNSTR < tracdb/trac.sql

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
