#!/bin/bash
# Start the dev container; works from any directory.
#   ./up.sh            reopen the last project
#   ./up.sh breeder    mount ws/breeder at /workspace (recreates the container)
set -euo pipefail

ROOT=$(cd "$(dirname "$0")" && pwd)

if [ $# -gt 0 ]; then
    WS_PROJECT=$1 exec devcontainer up --workspace-folder "$ROOT" --remove-existing-container
fi
exec devcontainer up --workspace-folder "$ROOT"
