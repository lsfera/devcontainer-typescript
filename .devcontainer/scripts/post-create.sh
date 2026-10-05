#!/bin/bash
set -euo pipefail

export PNPM_HOME=/usr/local/share/pnpm
export PATH="$PNPM_HOME:$PATH"

#######
# System packages
#######
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update
sudo apt-get install -y --no-install-recommends ripgrep git
curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | bash
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*

#######
# Git
#######
git config --global --get-all safe.directory | grep -qx /workspace \
    || git config --global --add safe.directory /workspace

#######
# Node / pnpm
#######
sudo mkdir -p node_modules "$PNPM_HOME"
sudo chown -R node node_modules "$PNPM_HOME"
npm install -g --allow-scripts=pnpm pnpm
npm install -g --allow-scripts=@anthropic-ai/claude-code @anthropic-ai/claude-code  # CLI used by post-start.sh to install plugins
pnpm self-update
if [ -f package.json ]; then
    pnpm install
else
    echo "No package.json in $(pwd); skipping pnpm install (check out a branch with code and run it manually)."
fi

#######
# SSH agent check
#######
if ! ssh-add -l >/dev/null 2>&1; then
    echo "WARNING: no SSH keys found via agent forwarding (SSH_AUTH_SOCK=${SSH_AUTH_SOCK:-unset})."
    echo "         Run 'ssh-add <your key>' on the host and rebuild the container."
fi

#######
# Runtime smoke test
#######
if ! /scripts/smoke-test.sh; then
    echo "WARNING: runtime smoke test failed; see FAIL lines above."
fi

#######
# Done
#######
