#!/bin/bash
# Start the dev container and attach VS Code to it; works from any directory.
#   ./up.sh            reopen the last project
#   ./up.sh breeder    mount ws/breeder at /workspace (recreates the container)
set -euo pipefail

ROOT=$(cd "$(dirname "$0")" && pwd)

args=(--workspace-folder "$ROOT")
if [ $# -gt 0 ]; then
    export WS_PROJECT=$1
    args+=(--remove-existing-container)
fi

# devcontainer logs to stderr; the result JSON is the only thing on stdout.
result=$(devcontainer up "${args[@]}")
container_id=$(printf '%s' "$result" | sed -n 's/.*"containerId":"\([^"]*\)".*/\1/p')
[ -n "$container_id" ] || { echo "up.sh: no containerId in: $result" >&2; exit 1; }

# Attach VS Code to the running container, in /workspace.
hex=$(printf '%s' "$container_id" | xxd -p | tr -d '\n')
exec code --folder-uri "vscode-remote://attached-container+$hex/workspace"
