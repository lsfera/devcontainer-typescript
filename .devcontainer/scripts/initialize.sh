#!/bin/bash
# Runs on the host before compose starts. Writes .devcontainer/.env, which compose
# reads for interpolation. WS_PROJECT picks which ws/<project> is mounted at
# /workspace: taken from the environment when set, otherwise the last one used.
#   ./up.sh breeder
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
ENV_FILE="$ROOT/.devcontainer/.env"

if [ -z "${WS_PROJECT:-}" ] && [ -f "$ENV_FILE" ]; then
    WS_PROJECT=$(sed -n 's/^WS_PROJECT=//p' "$ENV_FILE")
fi
WS_PROJECT=${WS_PROJECT:-circuit-breaker}

if [ ! -d "$ROOT/ws/$WS_PROJECT" ]; then
    echo "No such project: ws/$WS_PROJECT" >&2
    exit 1
fi

{
    echo "LOCAL_HOST_WORKSPACE=$ROOT"
    echo "WS_PROJECT=$WS_PROJECT"
} > "$ENV_FILE"
echo "Mounting ws/$WS_PROJECT at /workspace"
