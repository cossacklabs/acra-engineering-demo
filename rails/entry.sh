#!/usr/bin/env bash

set -Eeuox pipefail

cat > /app/config/database.yml <<EOF
default: &default
  adapter: postgresql
  host: $ACRA_SERVER_HOST
  port: $ACRA_SERVER_PORT
  database: $POSTGRES_DB
  username: $POSTGRES_USER
  password: $POSTGRES_PASSWORD
  sslcert: $TLS_CLIENT_CERT
  sslkey: $TLS_CLIENT_KEY
  sslrootcert: $TLS_ROOT_CERT
  sslmode: verify-full
  timeout: 5000
development:
  <<: *default
test:
  <<: *default
  min_messages: warning
  pool: 5
  timeout: 5000
staging:
  <<: *default
  min_messages: error
  pool: 30
  reconnect: true
production:
  <<: *default
  min_messages: error
  pool: 30
  reconnect: true
EOF

echo 'Waiting for PostgreSQL...'
while ! pg_isready -h $POSTGRES_HOST -p 5432; do
    sleep 1
done


ACRA_PUB_KEY_PATH=$(find "$PUBLIC_KEY_DIR" -type f -name \*.pub -print)
ACRA_WRITER_PUBLIC_KEY=$(cat "$ACRA_PUB_KEY_PATH" | base64)
cat > /app/config/secrets.yml <<EOF
development:
  secret_key_base: 01ade4a4dc594f4e2f1711f225adc0ad38b1f4e0b965191a43eea8a658a97d8d5f7a1255791c491f14ca638d4bbc7d82d8990040e266e3d898670605f2e5676f
  acra_public_key: $ACRA_WRITER_PUBLIC_KEY
test:
  secret_key_base: 482e75fe0b819896e400fa4be69a0535382e73a98f147d9f898d6bf2d2d705c85834a91b765b0a4ba018493c38ebaf355acae8ca1f9e654e9c52c6fa969042ac
staging:
  secret_key_base: <%= ENV["SECRET_KEY_BASE"] %>
production:
  secret_key_base: <%= ENV["SECRET_KEY_BASE"] %>
EOF

bin/rails db:migrate RAILS_ENV=development
exec bundle exec rails server -b 0.0.0.0