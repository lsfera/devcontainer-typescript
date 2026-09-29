#!/bin/bash
# Runs on every container start. Claude state lives in /workspace subfolders so it
# survives rebuilds:
#   ~/.claude-mem     -> /workspace/.claude-mem            (claude-mem data)
#   ~/.claude/plugins -> /workspace/.claude-plugins-cache  (marketplaces + plugin cache)
#   /workspace/.claude                                     (project/local settings)
set -euo pipefail

# Point $2 at directory $1, moving over anything already in a real $2.
link_dir() {
    local target=$1 link=$2
    mkdir -p "$target" "$(dirname "$link")"
    if [ -d "$link" ] && [ ! -L "$link" ]; then
        cp -a "$link/." "$target/"
        rm -rf "$link"
    fi
    ln -sfn "$target" "$link"
}

link_dir /workspace/.claude-mem ~/.claude-mem
link_dir /workspace/.claude-plugins-cache ~/.claude/plugins

#######
# Keep Claude state out of the workspace repo (local only, never committed)
#######
if [ -d /workspace/.git ]; then
    EXCLUDE=/workspace/.git/info/exclude
    mkdir -p "$(dirname "$EXCLUDE")"
    for p in .claude/ .claude-mem/ .claude-plugins-cache/; do
        grep -qxF "$p" "$EXCLUDE" 2>/dev/null || echo "$p" >> "$EXCLUDE"
    done
fi

#######
# claude-mem plugin: its hooks fail with "plugin scripts not found" when the
# plugin is enabled but its scripts are missing from the plugin cache.
#######
claude_mem_installed() {
    local d
    for d in ~/.claude/plugins/cache/thedotmack/claude-mem/*/; do
        [ -e "${d}.orphaned_at" ] && continue
        [ -f "${d}scripts/bun-runner.js" ] && [ -f "${d}scripts/worker-service.cjs" ] && return 0
    done
    return 1
}

if ! claude_mem_installed; then
    if ! command -v claude >/dev/null 2>&1; then
        echo "WARNING: claude CLI not found; cannot install claude-mem."
    elif ! (cd /workspace &&
            { claude plugin marketplace list | grep -q thedotmack ||
              claude plugin marketplace add thedotmack/claude-mem; } &&
            claude plugin install claude-mem@thedotmack --scope local); then
        echo "WARNING: claude-mem install failed; its hooks will report 'plugin scripts not found'."
    fi
fi

#######
# SSH / rtk
#######
mkdir -p ~/.ssh
ssh-keyscan -H github.com >> ~/.ssh/known_hosts
rtk init -g
