#!/usr/bin/env bash

set -eo pipefail

acraengdemo_raise() {
    echo -e "\\nERROR: $*\\n" >&2
    exit 1
}

acraengdemo_detect_os() {
    platform=$(uname | tr '[:upper:]' '[:lower:]')
    case "$platform" in
        (linux)
            if [[ -f '/etc/os-release' ]]; then
                . /etc/os-release
                os="${ID,,}"
                if [ -z "${VERSION_ID:-}" ]; then
                    os_ver="unknown"
                else
                    os_ver="${VERSION_ID%%.*}"
                fi
                case "$os" in
                    (debian)
                        os_ver_name="${VERSION#*(}"
                        os_ver_name="${os_ver_name%)}"
                        ;;
                    (ubuntu)
                        if [[ "$VERSION_ID" == '14.04' ]]; then
                            os_ver_name='trusty'
                        else
                            os_ver_name="${VERSION_CODENAME:-${os_ver}}"
                        fi
                        ;;
                    (*)
                        os_ver_name="${VERSION_CODENAME:-${os_ver}}"
                        ;;
                esac
            else
                acraengdemo_raise 'can not detect Linux version.'
            fi
            ;;
        (darwin)
            os='macosx'
            os_ver="$(sw_vers -productVersion | grep -Eo '^\d+\.\d+')"
            os_ver_name="$os_ver"
            ;;
        (*)
            acraengdemo_raise "Sorry, the '$(uname)' platform is not supported."
            ;;
    esac
}

acraengdemo_help() {
    echo "
Usage:
    run.sh <demo_project_name>

    where <demo_project_name> can be one of:
$(for p in ${PROJECTS_SUPPORTED[@]}; do echo -e '    - '$p; done)

Description:
    This script will prepare the environment and launch the selected
    demonstration project.

"
}

acraengdemo_parse_args() {
    if [ "$#" -ne '1' ]; then
        acraengdemo_help
        exit 1
    fi
    if [[ "$1" =~ (help|--help|-\?|--\?) ]]; then
        acraengdemo_help
        exit 0
    fi
    demo_project_name="$1"
}

acraengdemo_check() {
    # Supported OS
    OS_SUPPORTED=( debian ubuntu centos macosx arch manjaro )
    [[ " ${OS_SUPPORTED[@]} " =~ " $os " ]] ||
        acraengdemo_raise "OS version '$os' is not supported."

    # Required tools
    for c in 'git' 'docker' 'docker-compose'; do
        if ! which "$c" 1>/dev/null; then
            acraengdemo_raise "'$c' required but not found."
        fi
    done
}

acraengdemo_cmd() {
    echo -e "\\n== ${2:-Run command}"
    echo -e ">> $1\\n"
    eval "$1"
}

acraengdemo_add_cleanup_cmd() {
    CLEANUP_CMDS+=( "$1" )
    CLEANUP_CMDS_DESC+=( "$2" )
}

acraengdemo_press_any_key() {
    read < /dev/tty -n 1 -s -r -p 'Press any key to continue...'
}

acraengdemo_info_django() {
    ETCHOSTS_PREFIX=''
    if [ "$(uname)" == 'Darwin' ]; then
        ETCHOSTS_PREFIX='/private'
    fi
    echo "
Please do not forget to add a temporary entry to the hosts file:

    echo 'SERVER_IP www.djangoproject.example' >> $ETCHOSTS_PREFIX/etc/hosts

    where SERVER_IP - IP address of the server with running Acra Engineering Demo.
"
    echo '
Resources that will become available after launch:

    * Django demo project admin cabinet - add entries to the demo site:
        http://www.djangoproject.example:8000/admin/
        Default user/password: admin/admin

    * Django demo project - here you can see the added materials:
        http://www.djangoproject.example:8000/weblog/

    * Web interface for PostgreSQL - see how the encrypted data is stored:
        http://www.djangoproject.example:8008
        Default user/password: test@test.test/test

    * PostgreSQL - also you can connect to DB directly:
        postgresql://www.djangoproject.example:5432
        Default admin user/password: postgres/test

    * Prometheus - examine the collected metrics:
        http://www.djangoproject.example:9090

    * Grafana - sample of dashboards with Acra metrics:
        http://www.djangoproject.example:3000

    * Jaeger - view traces:
        http://www.djangoproject.example:16686


'
    acraengdemo_press_any_key
}

acraengdemo_info_django-transparent() {
    acraengdemo_info_django
}

acraengdemo_info_python() {
    echo '
Resources that will become available after launch:

      Run example (write, read):
        docker exec -it python_python_1 \
            python /app/example.py --data="some data" --public_key="path-to-key"
        docker exec -it python_python_1 \
            python /app/example.py --print --public_key="path-to-key"

    * Web interface for PostgreSQL - see how the encrypted data is stored:
        http://$HOST:8008
        Default user/password: test@test.test/test

    * PostgreSQL - also you can connect to DB directly:
        postgresql://$HOST:5432
        Default admin user/password: postgres/test

    * Prometheus - examine the collected metrics:
        http://$HOST:9090

    * Grafana - sample of dashboards with Acra metrics:
        http://$HOST:3000

    * Jaeger - view traces:
        http://$HOST:16686


    where are HOST is the IP address of the server with running Acra
    Engineering Demo. If you run this demo on the same host, from
    which you will connect, use "localhost".

'
    acraengdemo_press_any_key
}


acraengdemo_info_cockroachdb() {
    echo '
Resources that will become available after launch:

    * Container with environment prepared for the python example. Folder with
      example scripts will be mounted to container, so you will be able to
      modify these scripts without stopping docker compose.

      Run example (write, read):
        docker exec -it cockroachdb_python_1 \
           extended_example.py --host=acra-server --port=9393 --data=data.json
        docker exec -it cockroachdb_python_1 \
           python3 extended_example.py --host=acra-server --port=9393 --print

    * CockroachDB - also you can connect to DB directly:
        postgresql://$HOST:26257
        Default user `root` and Database `defaultdb`

    * Prometheus - examine the collected metrics:
        http://$HOST:9090

    * Grafana - sample of dashboards with Acra metrics:
        http://$HOST:3000

    * Jaeger - view traces:
        http://$HOST:16686


    where are HOST is the IP address of the server with running Acra
    Engineering Demo. If you run this demo on the same host, from
    which you will connect, use "localhost".

'
    acraengdemo_press_any_key
}


acraengdemo_info_python-mysql-postgresql() {
    echo '
Resources that will become available after launch:

    * Container with environment prepared for the python example. Folder with
      example scripts will be mounted to container, so you will be able to
      modify these scripts without stopping docker compose.

      Run example (write, read):
        docker exec -it python-mysql_python_1 python3 \
        extended_example.py --host=acra-server --port=9393 --data=data.json

        docker exec -it python-mysql_python_1 python3 \
        extended_example.py --host=acra-server --port=9393 --print

    * Web interface for MySQL - see how the encrypted data is stored:
        http://$HOST:8080
        Default user/password: test@test.test/test

    * MySQL - also you can connect to DB directly:
        mysql://$HOST:3306
        Default admin user/password: test/test

    * Web interface for PostgreSQL - see how the encrypted data is stored:
        http://$HOST:8008
        Default user/password: test@test.test/test

    * PostgreSQL - also you can connect to DB directly:
        postgresql://$HOST:5432
        Default admin user/password: postgres/test

    * Prometheus - examine the collected metrics:
        http://$HOST:9090

    * Grafana - sample of dashboards with Acra metrics:
        http://$HOST:3000

    * Jaeger - view traces:
        http://$HOST:16686


    where are HOST is the IP address of the server with running Acra
    Engineering Demo. If you run this demo on the same host, from
    which you will connect, use "localhost".

'
    acraengdemo_press_any_key
}

acraengdemo_info_db-acra-migration() {
    echo '
Resources that will become available after launch:

    * Container with environment prepared for the migration example. Folder with
      example scripts will be mounted to container, so you will be able to
      modify these scripts without stopping docker compose.

    * Web interface for PostgreSQL - see how the encrypted data is stored:
        http://$HOST:8008
        Default user/password: test@test.test/test

    * PostgreSQL - also you can connect to DB directly:
        postgresql://$HOST:5432
        Default admin user/password: postgres/test

    where are HOST is the IP address of the server with running Acra
    Engineering Demo. If you run this demo on the same host, from
    which you will connect, use "localhost".
'
    acraengdemo_press_any_key
}

acraengdemo_info_acra-translator() {
    echo '
Resources that will become available after launch:

    * Container with environment prepared for the AcraTransaltor example.

    * Web interface for MongoDB - see how the encrypted data is stored:
        http://$HOST:8081
        BasicAuth user/password: test/test

    * MongoDB - also you can connect to DB directly:
        mongodb://$HOST:27017
        Default admin user/password: root/password

    * GO Server - API server integrated with AcraTransaltor and MongoDB:
        http://$SWAGGER_HOST:8008/swagger/index.html#/ - swagger for available API

    where are HOST is the IP address of the server with running Acra
    Engineering Demo. If you run this demo on the same host, from
    which you will connect, use "localhost".
'
    acraengdemo_press_any_key
}

acraengdemo_info_rails() {
    ETCHOSTS_PREFIX=''
    if [ "$(uname)" == 'Darwin' ]; then
        ETCHOSTS_PREFIX='/private'
    fi
    echo "
Please do not forget to add a temporary entry to the hosts file:

    echo 'SERVER_IP www.rubygems.example' >> $ETCHOSTS_PREFIX/etc/hosts

    where SERVER_IP - IP address of the server with running Acra Engineering Demo.
"
    echo '
Resources that will become available after launch:

    * rubygems.org demo project - here you can see the added materials:
        http://www.rubygems.example:8000

    * Web interface for PostgreSQL - see how the encrypted data is stored:
        http://www.rubygems.example:8008
        Default user/password: test@test.test/test

    * PostgreSQL - also you can connect to DB directly:
        postgresql://www.rubygems.example:5432
        Default admin user/password: rubygems/rubygems

    * Prometheus - examine the collected metrics:
        http://www.rubygems.example:9090

    * Grafana - sample of dashboards with Acra metrics:
        http://www.rubygems.example:3000

    * AcraConnector - play with the encryption system directly:
        tcp://www.rubygems.example:9494

    * Jaeger - view traces:
        http://www.rubygems.example:16686


'
    acraengdemo_press_any_key
}

acraengdemo_info_timescaledb() {
    echo '
Resources that will become available after launch:

    * TimescaleDB - also you can connect to DB directly:
        postgresql://$HOST:5432
        Default admin user/password: postgres/test

    * Web interface for TimescaleDB - see how the encrypted data is stored:
        http://$HOST:8008
        Default user/password: test@test.test/test

    * AcraConnector - play with the encryption system directly:
        tcp://$HOST:9494

    * Prometheus - examine the collected metrics:
        http://$HOST:9090

    * Grafana - sample dashboard with TimescaleDB data:
        http://$HOST:3000

    where are HOST is the IP address of the server with running Acra
    Engineering Demo. If you run this demo on the same host, from
    which you will connect, use "localhost".

'
    acraengdemo_press_any_key
}


acraengdemo_info_python-searchable() {
    echo '
Resources that will become available after launch:

    * Container with environment prepared for the python example. Folder with
      example scripts will be mounted to container, so you will be able to
      modify these scripts without stopping docker compose.

      Insert data into PostgreSQL:
        docker exec -it python-searchable-python-1 \
            python /app/searchable.py --postgresql --data=searchable.json

      Read data from PostgreSQL:
        docker exec -it python-searchable-python-1 \
            python /app/searchable.py --postgresql --print

      To use MySQL instead of PostgreSQL, provide `--mysql` flag
      instead of `--postgresql`.

    * Web interface for PostgreSQL - see how the encrypted data is stored:
        http://$HOST:8008
        Default user/password: test@test.test/test

    * PostgreSQL - also you can connect to DB directly:
        postgresql://$HOST:5432
        Default admin user/password: test/test

    * Web interface for MySQL - see how the encrypted data is stored:
        http://$HOST:8080
        Default user/password: test@test.test/test

    * MySQL - also you can connect to DB directly:
        mysql://$HOST:3306
        Default admin user/password: test/test

    * Prometheus - examine the collected metrics:
        http://$HOST:9090

    * Grafana - sample of dashboards with Acra metrics:
        http://$HOST:3000

    * Jaeger - view traces:
        http://$HOST:16686


    where are HOST is the IP address of the server with running Acra
    Engineering Demo. If you run this demo on the same host, from
    which you will connect, use "localhost".

'
    acraengdemo_press_any_key
}

acraengdemo_git_clone_acraengdemo() {
    COSSACKLABS_ACRAENGDEMO_VCS_URL=${COSSACKLABS_ACRAENGDEMO_VCS_URL:-'https://github.com/cossacklabs/acra-engineering-demo'}
    COSSACKLABS_ACRAENGDEMO_VCS_BRANCH=${COSSACKLABS_ACRAENGDEMO_VCS_BRANCH:-master}
    if [ -d "acra-engineering-demo" ]; then
      git -C ./acra-engineering-demo/ "$COSSACKLABS_ACRAENGDEMO_VCS_BRANCH";
    else
      acraengdemo_cmd \
        "git clone --depth 1 -b $COSSACKLABS_ACRAENGDEMO_VCS_BRANCH $COSSACKLABS_ACRAENGDEMO_VCS_URL" \
        "Cloning acra-engineering-demo"
    fi;
    COSSACKLABS_ACRAENGDEMO_VCS_REF=$(git -C ./acra-engineering-demo/ rev-parse --verify HEAD)
}

acraengdemo_run_compose() {
    DC_FILE="$PROJECT_DIR/$demo_project_name/docker-compose.$demo_project_name.yml"

    acraengdemo_add_cleanup_cmd \
        'docker image prune --all --force --filter "label=com.cossacklabs.product.name=acra-engdemo"' \
        'remove custom built images'
    acraengdemo_cmd "$COMPOSE_ENV_VARS docker-compose -f $DC_FILE pull" 'Pull fresh images'

    acraengdemo_add_cleanup_cmd \
        "docker-compose -f $DC_FILE down -v" \
        'stop docker-compose'
    acraengdemo_cmd "$COMPOSE_ENV_VARS docker-compose -f $DC_FILE up --build" 'Starting docker-compose'
}

acraengdemo_launch_project_django() {
    COSSACKLABS_DJANGO_VCS_URL='https://github.com/cossacklabs/djangoproject.com'
    COSSACKLABS_DJANGO_VCS_BRANCH=${COSSACKLABS_DJANGO_VCS_BRANCH:-master}
    COSSACKLABS_DJANGO_VCS_REF='621e18f928db903d73b84788b3e3c9df9e83dd4c'

    COMPOSE_ENV_VARS="${COMPOSE_ENV_VARS} "\
"COSSACKLABS_DJANGO_VCS_URL=\"$COSSACKLABS_DJANGO_VCS_URL\" "\
"COSSACKLABS_DJANGO_VCS_BRANCH=\"$COSSACKLABS_DJANGO_VCS_BRANCH\" "\
"COSSACKLABS_DJANGO_VCS_REF=\"$COSSACKLABS_DJANGO_VCS_REF\" "

    acraengdemo_run_compose
}

acraengdemo_launch_project_django-transparent() {
    COSSACKLABS_DJANGO_VCS_URL='https://github.com/django/djangoproject.com'
    COSSACKLABS_DJANGO_VCS_BRANCH=${COSSACKLABS_DJANGO_VCS_BRANCH:-main}
    COSSACKLABS_DJANGO_VCS_REF='67d1afa8fb8e1a1b2263989fbd8d3d3a8ae5b4c5'

    COMPOSE_ENV_VARS="${COMPOSE_ENV_VARS} "\
"COSSACKLABS_DJANGO_VCS_URL=\"$COSSACKLABS_DJANGO_VCS_URL\" "\
"COSSACKLABS_DJANGO_VCS_BRANCH=\"$COSSACKLABS_DJANGO_VCS_BRANCH\" "\
"COSSACKLABS_DJANGO_VCS_REF=\"$COSSACKLABS_DJANGO_VCS_REF\" "

    acraengdemo_run_compose
}

acraengdemo_launch_project_acra-translator() {
    COSSACKLABS_GO_TRANSLATOR_DEMO_VCS_URL='https://github.com/cossacklabs/acra-engineering-demo'
    COSSACKLABS_GO_TRANSLATOR_DEMO_VCS_BRANCH=${COSSACKLABS_DJANGO_VCS_BRANCH:-master}
    COSSACKLABS_GO_TRANSLATOR_DEMO_VCS_REF='eb921ff32d76b79af4d9789d8bcb1e994b5777ef'

    COMPOSE_ENV_VARS="${COMPOSE_ENV_VARS} "\
"COSSACKLABS_GO_TRANSLATOR_DEMO_VCS_URL=\"$COSSACKLABS_GO_TRANSLATOR_DEMO_VCS_URL\" "\
"COSSACKLABS_GO_TRANSLATOR_DEMO_VCS_BRANCH=\"$COSSACKLABS_GO_TRANSLATOR_DEMO_VCS_BRANCH\" "\
"COSSACKLABS_GO_TRANSLATOR_DEMO_VCS_REF=\"$COSSACKLABS_GO_TRANSLATOR_DEMO_VCS_REF\" "

    acraengdemo_run_compose
}

acraengdemo_launch_project_db-acra-migration() {
    COSSACKLABS_ACRA_VCS_URL='https://github.com/cossacklabs/acra-engineering-demo'
    COSSACKLABS_ACRA_VCS_BRANCH=${COSSACKLABS_DJANGO_VCS_BRANCH:-master}
    COSSACKLABS_ACRA_VCS_REF='eb921ff32d76b79af4d9789d8bcb1e994b5777ef'

    COMPOSE_ENV_VARS="${COMPOSE_ENV_VARS} "\
"COSSACKLABS_ACRA_VCS_URL=\"$COSSACKLABS_GO_TRANSLATOR_DEMO_VCS_URL\" "\
"COSSACKLABS_ACRA_VCS_BRANCH=\"$COSSACKLABS_GO_TRANSLATOR_DEMO_VCS_BRANCH\" "\
"COSSACKLABS_ACRA_VCS_REF=\"$COSSACKLABS_GO_TRANSLATOR_DEMO_VCS_REF\" "

    acraengdemo_run_compose
}

acraengdemo_launch_project_python() {
    COSSACKLABS_ACRA_VCS_URL=${COSSACKLABS_ACRA_VCS_URL:-'https://github.com/cossacklabs/acra'}
    COSSACKLABS_ACRA_VCS_REF=${COSSACKLABS_ACRA_VCS_REF:-'34e162b335a3d2c248b8fd1e294c25bd5c78350e'}
    if [ -d "${PROJECT_DIR}/acra" ]; then
      git -C "${PROJECT_DIR}/acra" checkout "$COSSACKLABS_ACRA_VCS_REF";
    else
      acraengdemo_cmd \
        "git clone --depth 1 $COSSACKLABS_ACRA_VCS_URL ${PROJECT_DIR}/acra && cd ${PROJECT_DIR}/acra  && git checkout $COSSACKLABS_ACRA_VCS_REF" \
        "Cloning Acra"
    fi;
    COSSACKLABS_ACRA_VCS_REF=$(git -C "${PROJECT_DIR}/acra" rev-parse --verify HEAD)
    acraengdemo_add_cleanup_cmd "rm -rf ${PROJECT_DIR}/acra" "remove cloned \"acra\" repository"

    COMPOSE_ENV_VARS="${COMPOSE_ENV_VARS} "\
"COSSACKLABS_ACRA_VCS_URL=\"$COSSACKLABS_ACRA_VCS_URL\" "\
"COSSACKLABS_ACRA_VCS_BRANCH=\"master\" "\
"COSSACKLABS_ACRA_VCS_REF=\"$COSSACKLABS_ACRA_VCS_REF\" "

    acraengdemo_run_compose
}

acraengdemo_launch_project_cockroachdb() {
    COSSACKLABS_ACRA_VCS_URL=${COSSACKLABS_ACRA_VCS_URL:-'https://github.com/cossacklabs/acra'}
     COSSACKLABS_ACRA_VCS_REF=${COSSACKLABS_ACRA_VCS_REF:-'e1773020a881a39d126724bd3992b9b436173fa0'}
    if [ -d "${PROJECT_DIR}/acra" ]; then
      git -C "${PROJECT_DIR}/acra" checkout "$COSSACKLABS_ACRA_VCS_REF";
    else
      acraengdemo_cmd \
        "git clone --depth 1 $COSSACKLABS_ACRA_VCS_URL ${PROJECT_DIR}/acra && cd ${PROJECT_DIR}/acra  && git checkout $COSSACKLABS_ACRA_VCS_REF" \
        "Cloning Acra"
    fi;
    COSSACKLABS_ACRA_VCS_REF=$(git -C "${PROJECT_DIR}/acra" rev-parse --verify HEAD)
    acraengdemo_add_cleanup_cmd "rm -rf ${PROJECT_DIR}/acra" "remove cloned \"acra\" repository"

    COMPOSE_ENV_VARS="${COMPOSE_ENV_VARS} "\
"COSSACKLABS_ACRA_VCS_URL=\"$COSSACKLABS_ACRA_VCS_URL\" "\
"COSSACKLABS_ACRA_VCS_BRANCH=\"master\" "\
"COSSACKLABS_ACRA_VCS_REF=\"$COSSACKLABS_ACRA_VCS_REF\" "

    acraengdemo_run_compose
}

acraengdemo_launch_project_python-mysql-postgresql() {
    COSSACKLABS_ACRA_VCS_URL=${COSSACKLABS_ACRA_VCS_URL:-'https://github.com/cossacklabs/acra'}
    # using commit instead of version/tag to use the commit with specific SqlAlchemy from examples/python
    # https://github.com/cossacklabs/acra/pull/669/commits/be2ab1a4440e105dee1423ae21da1ee74e842801
    # and some examples/python fixes
    # https://github.com/cossacklabs/acra/commit/e1773020a881a39d126724bd3992b9b436173fa0
    COSSACKLABS_ACRA_VCS_REF=${COSSACKLABS_ACRA_VCS_REF:-'e1773020a881a39d126724bd3992b9b436173fa0'}
    if [ -d "${PROJECT_DIR}/acra" ]
    then
      git -C "${PROJECT_DIR}/acra" checkout "$COSSACKLABS_ACRA_VCS_REF";
    else
      # we should clone into folder with acra-eng-demo to allow mount files from acra/examples/python folder
      acraengdemo_cmd \
        "git clone $COSSACKLABS_ACRA_VCS_URL ${PROJECT_DIR}/acra && cd ${PROJECT_DIR}/acra  && git checkout $COSSACKLABS_ACRA_VCS_REF" \
        "Cloning Acra"
    fi;

    acraengdemo_add_cleanup_cmd "rm -rf ${PROJECT_DIR}/acra" "remove cloned \"acra\" repository"

    COMPOSE_ENV_VARS="${COMPOSE_ENV_VARS} "\
"COSSACKLABS_ACRA_VCS_URL=\"$COSSACKLABS_ACRA_VCS_URL\" "\
"COSSACKLABS_ACRA_VCS_BRANCH=\"master\" "\
"COSSACKLABS_ACRA_VCS_REF=\"$COSSACKLABS_ACRA_VCS_REF\" "

    acraengdemo_run_compose
}

acraengdemo_launch_project_rails() {
    COSSACKLABS_RUBYGEMS_VCS_URL='https://github.com/cossacklabs/rubygems.org'
    COSSACKLABS_RUBYGEMS_VCS_BRANCH=${COSSACKLABS_RUBYGEMS_VCS_BRANCH:-master}
    COSSACKLABS_RUBYGEMS_VCS_REF='05c7338a5ecc89c7562bbe0a2d869d4e8ba601b5'

    COMPOSE_ENV_VARS="${COMPOSE_ENV_VARS} "\
"COSSACKLABS_RUBYGEMS_VCS_URL=\"$COSSACKLABS_RUBYGEMS_VCS_URL\" "\
"COSSACKLABS_RUBYGEMS_VCS_BRANCH=\"$COSSACKLABS_RUBYGEMS_VCS_BRANCH\" "\
"COSSACKLABS_RUBYGEMS_VCS_REF=\"$COSSACKLABS_RUBYGEMS_VCS_REF\" "

    acraengdemo_run_compose
}

acraengdemo_launch_project_timescaledb() {
    acraengdemo_run_compose
}


acraengdemo_launch_project_python-searchable() {
    COSSACKLABS_ACRA_VCS_URL=${COSSACKLABS_ACRA_VCS_URL:-'https://github.com/cossacklabs/acra'}
    # using commit instead of version/tag to use the commit with specific SqlAlchemy from examples/python
    # https://github.com/cossacklabs/acra/pull/669/commits/be2ab1a4440e105dee1423ae21da1ee74e842801
    # and some examples/python fixes
    # https://github.com/cossacklabs/acra/commit/e1773020a881a39d126724bd3992b9b436173fa0
    COSSACKLABS_ACRA_VCS_REF=${COSSACKLABS_ACRA_VCS_REF:-'e1773020a881a39d126724bd3992b9b436173fa0'}
    if [ -d "${PROJECT_DIR}/acra" ]
    then
      git -C "${PROJECT_DIR}/acra" checkout "$COSSACKLABS_ACRA_VCS_REF";
    else
      # we should clone into folder with acra-eng-demo to allow mount files from acra/examples/python folder
      acraengdemo_cmd \
        "git clone $COSSACKLABS_ACRA_VCS_URL ${PROJECT_DIR}/acra && cd ${PROJECT_DIR}/acra  && git checkout $COSSACKLABS_ACRA_VCS_REF" \
        "Cloning Acra"
    fi;
    COSSACKLABS_ACRA_VCS_REF=$(git -C "${PROJECT_DIR}/acra" rev-parse --verify HEAD)
    acraengdemo_add_cleanup_cmd "rm -rf ${PROJECT_DIR}/acra" "remove cloned \"acra\" repository"

    COMPOSE_ENV_VARS="${COMPOSE_ENV_VARS} "\
"COSSACKLABS_ACRA_VCS_URL=\"$COSSACKLABS_ACRA_VCS_URL\" "\
"COSSACKLABS_ACRA_VCS_BRANCH=\"$COSSACKLABS_ACRA_VCS_BRANCH\" "\
"COSSACKLABS_ACRA_VCS_REF=\"$COSSACKLABS_ACRA_VCS_REF\" "

    acraengdemo_run_compose
}

acraengdemo_launch_project() {
    [[ " ${PROJECTS_SUPPORTED[@]} " =~ " $demo_project_name " ]] ||
        acraengdemo_raise "unknown demo project '$demo_project_name'."

    echo -e "\\n## Selected demo project: $demo_project_name"
    if [ -d ".git" ]; then
      echo -e "\\n== Work in current directory\\n"
      PROJECT_DIR="$(pwd)"
      COSSACKLABS_ACRAENGDEMO_VCS_URL=${COSSACKLABS_ACRAENGDEMO_VCS_URL:-'https://github.com/cossacklabs/acra-engineering-demo'}
      COSSACKLABS_ACRAENGDEMO_VCS_BRANCH=${COSSACKLABS_ACRAENGDEMO_VCS_BRANCH:-master}
      COSSACKLABS_ACRAENGDEMO_VCS_REF=$(git rev-parse --verify HEAD)
    else
      echo -e "\\n== Create temporary directory\\n>> mktemp -d"
      PROJECT_DIR="$(mktemp -d)"
      echo "++ Created directory $PROJECT_DIR"
      acraengdemo_add_cleanup_cmd "rm -rf $PROJECT_DIR" "remove temporary directory"
      acraengdemo_cmd "cd $PROJECT_DIR" 'Go into project dir'
      acraengdemo_git_clone_acraengdemo
      PROJECT_DIR="${PROJECT_DIR}/acra-engineering-demo"
    fi;

    # assign default env variables for compose file
    COMPOSE_ENV_VARS="COSSACKLABS_ACRAENGDEMO_VCS_URL=\"$COSSACKLABS_ACRAENGDEMO_VCS_URL\" "\
"COSSACKLABS_ACRAENGDEMO_VCS_BRANCH=\"$COSSACKLABS_ACRAENGDEMO_VCS_BRANCH\" "\
"COSSACKLABS_ACRAENGDEMO_VCS_REF=\"$COSSACKLABS_ACRAENGDEMO_VCS_REF\" "\
"COSSACKLABS_ACRAENGDEMO_BUILD_DATE=\"$(date -u +'%Y-%m-%dT%H:%M:%SZ')\" "

    eval "acraengdemo_info_$demo_project_name"
    eval "acraengdemo_launch_project_$demo_project_name"
}

acraengdemo_int() {
    wait
    acraengdemo_post
    exit 0
}

acraengdemo_main() {
    BASEDIR=$(pwd)

    CLEANUP_CMDS=( )
    CLEANUP_CMDS_DESC=( )

    trap acraengdemo_int INT
    acraengdemo_launch_project
}

acraengdemo_post() {
    local FILE_CLEANUP="$BASEDIR/acraengdemo_cleanup.sh"
    echo -e "#!/usr/bin/env bash\\n\\nset -x\\n\\n" > "$FILE_CLEANUP"
    chmod +x "$FILE_CLEANUP"

    if [ ${#CLEANUP_CMDS[*]} -gt 0 ]; then
        echo -e '\n\nDemo stopped. Clean up commands:'
        local cleanup_index_max=$(( ${#CLEANUP_CMDS[@]} -1 ))
        local reverse_indexes=$(seq ${cleanup_index_max} -1 0)
        for i in $reverse_indexes; do
            echo -e "\\t* ${CLEANUP_CMDS_DESC[$i]}:"
            echo -e "\\t\\t${CLEANUP_CMDS[$i]}"
            echo "# ${CLEANUP_CMDS_DESC[$i]}" >> "$FILE_CLEANUP"
            echo "${CLEANUP_CMDS[$i]}" >> "$FILE_CLEANUP"
        done
    fi

    echo -e '\nAll these commands were saved to the script:'
    echo -e "\\t$FILE_CLEANUP"
    echo -e '\nRun it to clean up. May require sudo to remove directories, created by docker.\n'
}

acraengdemo_init() {
    PROJECTS_SUPPORTED=( django django-transparent python python-mysql-postgresql rails timescaledb cockroachdb python-searchable acra-translator db-acra-migration )
}

acraengdemo_run() {
    acraengdemo_init
    acraengdemo_detect_os
    acraengdemo_parse_args "$@"
    acraengdemo_check
    acraengdemo_main
    acraengdemo_post
}

acraengdemo_run "$@"
