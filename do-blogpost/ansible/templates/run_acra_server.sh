#!/usr/bin/env bash

set -euo pipefail

KEYS_DIR="$1"
PORT="$2"

docker stop acra-server &>/dev/null || true && docker rm acra-server &>/dev/null || true
docker run -d \
        --name acra-server --restart=always \
        -v "/etc/acra:/etc/acra" \
        -v "/etc/ssl:/etc/ssl:ro" \
        -v "/usr/share/ca-certificates:/usr/share/ca-certificates:ro" \
        -v "/usr/local/share/ca-certificates:/usr/local/share/ca-certificates:ro" \
        -e "ACRA_MASTER_KEY=$(cat "${KEYS_DIR}/ACRA_MASTER_KEY")" \
        -p "${PORT}:9393" \
        cossacklabs/acra-server:0.85.0 \
        --config_file=/etc/acra/cfg/acra_server_config.yaml \
        -v
