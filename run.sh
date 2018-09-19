#!/usr/bin/env bash

set -euo pipefail

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
                os_ver="${VERSION_ID%%.*}"
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
    echo '
Usage:
    run.sh demo_project_name

Description:
    This script will prepare the environment and launch the selected
    demonstration project.

'
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
    OS_SUPPORTED=( debian ubuntu centos macosx )
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

acraengdemo_info_django() {
    ETCHOSTS_PREFIX=''
    if [ "$(uname)" == 'Darwin' ]; then
        ETCHOSTS_PREFIX='/private'
    fi
    echo "
Please do not forget to add a temporary entry to the hosts file:

    echo 'SERVER_IP www.djangoproject.test' >> $ETCHOSTS_PREFIX/etc/hosts

    where SERVER_IP - IP address of the server with running Acra Engineering Demo.
"
    echo '
Resources that will become available after launch:
    * Django demo project:
        http://www.djangoproject.test:8000
    * Django demo project admin cabinet:
        http://www.djangoproject.test:8000/admin
        Default user/password: admin/admin
    * PostgreSQL
        postgresql://$SERVER_IP:5432
        Default admin user/password: postgres/test
    * Web interface for PostgreSQL
        http://$SERVER_IP:8008
        Default user/password: test/test
    * AcraConnector
        tcp://$SERVER_IP:9494
    * AcraWebConfig
        http://$SERVER_IP:8001
        Default user/password: test/test

'
    read -n 1 -s -r -p 'Press any key to continue...'
}

acraengdemo_launch_project_django() {
    acraengdemo_info_django

    COSSACKLABS_DJANGO_VCS_URL='https://github.com/cossacklabs/djangoproject.com'
    COSSACKLABS_DJANGO_VCS_BRANCH=${COSSACKLABS_DJANGO_VCS_BRANCH:-master}
    acraengdemo_cmd \
        "git clone --depth 1 -b $COSSACKLABS_DJANGO_VCS_BRANCH $COSSACKLABS_DJANGO_VCS_URL" \
        "Cloning djangoproject.com"
    COSSACKLABS_DJANGO_VCS_REF=$(git -C ./djangoproject.com/ rev-parse --verify HEAD)

    COSSACKLABS_ACRAENGDEMO_VCS_URL='https://github.com/cossacklabs/acra-engineering-demo'
    COSSACKLABS_ACRAENGDEMO_VCS_BRANCH=${COSSACKLABS_ACRAENGDEMO_VCS_BRANCH:-master}
    acraengdemo_cmd \
        "git clone --depth 1 -b $COSSACKLABS_ACRAENGDEMO_VCS_BRANCH $COSSACKLABS_ACRAENGDEMO_VCS_URL" \
        "Cloning acra-engineering-demo"
    COSSACKLABS_ACRAENGDEMO_VCS_REF=$(git -C ./acra-engineering-demo/ rev-parse --verify HEAD)

    DC_FILE="acra-engineering-demo/$demo_project_name/docker-compose.$demo_project_name.yml"

    COMPOSE_ENV_VARS="COSSACKLABS_ACRAENGDEMO_VCS_URL=\"$COSSACKLABS_ACRAENGDEMO_VCS_URL\" "\
"COSSACKLABS_ACRAENGDEMO_VCS_BRANCH=\"$COSSACKLABS_ACRAENGDEMO_VCS_BRANCH\" "\
"COSSACKLABS_ACRAENGDEMO_VCS_REF=\"$COSSACKLABS_ACRAENGDEMO_VCS_REF\" "\
"COSSACKLABS_DJANGO_VCS_URL=\"$COSSACKLABS_DJANGO_VCS_URL\" "\
"COSSACKLABS_DJANGO_VCS_BRANCH=\"$COSSACKLABS_DJANGO_VCS_BRANCH\" "\
"COSSACKLABS_DJANGO_VCS_REF=\"$COSSACKLABS_DJANGO_VCS_REF\" "\
"COSSACKLABS_ACRAENGDEMO_BUILD_DATE=\"$(date -u +'%Y-%m-%dT%H:%M:%SZ')\""

    acraengdemo_add_cleanup_cmd \
        'docker image prune --all --force --filter "label=com.cossacklabs.product.name=acra-engdemo"' \
        'remove custom built images'
    acraengdemo_cmd "$COMPOSE_ENV_VARS docker-compose -f $DC_FILE pull" 'Pull fresh images'

    acraengdemo_add_cleanup_cmd \
        "docker-compose -f $PROJECT_DIR/$DC_FILE down" \
        'stop docker-compose'
    acraengdemo_cmd "$COMPOSE_ENV_VARS docker-compose -f $DC_FILE up" 'Starting docker-compose'
}

acraengdemo_launch_project() {
    PROJECTS_SUPPORTED=( django )
    [[ " ${PROJECTS_SUPPORTED[@]} " =~ " $demo_project_name " ]] ||
        acraengdemo_raise "unknown demo project '$demo_project_name'."

    echo -e "\\n## Selected demo project: $demo_project_name"

    echo -e "\\n== Create temporary directory\\n>> mktemp -d"
    PROJECT_DIR="$(mktemp -d)"
    echo "++ Created directory $PROJECT_DIR"
    acraengdemo_add_cleanup_cmd "rm -rf $PROJECT_DIR" "remove temporary directory"
    acraengdemo_cmd "cd $PROJECT_DIR" 'Go into project dir'

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
    echo '# Self-deleting' >> "$FILE_CLEANUP"
    echo 'rm -- "$0"' >> "$FILE_CLEANUP"

    echo -e '\nAll these commands were saved to the script:'
    echo -e "\\t$FILE_CLEANUP"
    echo -e '\nRun it to clean up. May require sudo to remove directories, created by docker.\n'
}

acraengdemo_run() {
    acraengdemo_detect_os
    acraengdemo_parse_args "$@"
    acraengdemo_check
    acraengdemo_main
    acraengdemo_post
}

acraengdemo_run "$@"
