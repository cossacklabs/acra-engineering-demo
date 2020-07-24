#!/usr/bin/env bash

set -euo pipefail

KEYS_DIR="$1"
CLIENT_ID="$2"

if [ ! -f "${KEYS_DIR}/ACRA_MASTER_KEY" ]; then
    dd if=/dev/urandom bs=4 count=8 2>/dev/null \
        | base64 > "${KEYS_DIR}/ACRA_MASTER_KEY"
fi

if ! ls "${KEYS_DIR}/acra-server"/* >/dev/null 2>&1; then
    docker run \
        --rm \
        -v "${KEYS_DIR}:/app.keys" \
        -e "ACRA_MASTER_KEY=$(cat "${KEYS_DIR}/ACRA_MASTER_KEY")" \
        cossacklabs/acra-keymaker:0.85.0 \
        --client_id=$CLIENT_ID \
        --generate_acrawriter_keys \
        --keys_output_dir=/app.keys/acra-server \
        --keys_public_output_dir=/app.keys/acra-server
fi

find "$KEYS_DIR"/* -type f | sort | awk '{print "  - "$1}'
