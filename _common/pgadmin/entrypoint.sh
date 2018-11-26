#!/bin/sh

if [ ! -f /var/lib/pgadmin/pgadmin4.db ]; then
    if [ -z "${PGADMIN_DEFAULT_EMAIL}" -o -z "${PGADMIN_DEFAULT_PASSWORD}" ]; then
        echo 'You need to specify PGADMIN_DEFAULT_EMAIL and PGADMIN_DEFAULT_PASSWORD environment variables'
        exit 1
    fi

    # Set the default username and password in a
    # backwards compatible way
    export PGADMIN_SETUP_EMAIL=${PGADMIN_DEFAULT_EMAIL}
    export PGADMIN_SETUP_PASSWORD=${PGADMIN_DEFAULT_PASSWORD}

    # Initialize DB before starting Gunicorn
    # Importing pgadmin4 (from this script) is enough
    python run_pgadmin.py
fi

# NOTE: currently pgadmin can run only with 1 worker due to sessions implementation
# Using --threads to have multi-threaded single-process worker

# Add server/database
PGADMIN_DEFAULT_PASSWORD_HASH=$( \
    echo "SELECT password FROM USER WHERE email='$PGADMIN_DEFAULT_EMAIL'" | \
    sqlite3 /var/lib/pgadmin/pgadmin4.db)
export PYTHONPATH="${PYTHONPATH}:/pgadmin4/pgadmin/utils"
POSTGRESQL_DB_PASSWORD_HASH=$( \
    python -c "import crypto; print(crypto.encrypt('$POSTGRES_PASSWORD', '$PGADMIN_DEFAULT_PASSWORD_HASH').decode())")
echo "insert into server "\
"(id,user_id,servergroup_id,name,host,port,maintenance_db,username,"\
"password,ssl_mode) "\
"values (1,1,1,'$POSTGRES_HOST','$POSTGRES_HOST','5432','$POSTGRES_DB','$POSTGRES_USER',"\
"'$POSTGRESQL_DB_PASSWORD_HASH','prefer');" | sqlite3 /var/lib/pgadmin/pgadmin4.db
export PYTHONPATH='/pgadmin4'

if [ ! -z ${PGADMIN_ENABLE_TLS} ]; then
    exec gunicorn --bind [::]:${PGADMIN_LISTEN_PORT:-443} -w 1 --threads ${GUNICORN_THREADS:-25} --access-logfile - --keyfile /certs/server.key --certfile /certs/server.cert run_pgadmin:app
else
    exec gunicorn --bind [::]:${PGADMIN_LISTEN_PORT:-80} -w 1 --threads ${GUNICORN_THREADS:-25} --access-logfile - run_pgadmin:app
fi
