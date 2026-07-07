#!/bin/bash
set -euo pipefail

DEVCONTAINER_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
containerWorkspaceFolder="$(dirname -- "$DEVCONTAINER_DIR")"
export containerWorkspaceFolder

sudo apt update && sudo apt install -y ripgrep ncat

sudo ln -sf /usr/share/zoneinfo/America/Chicago /etc/localtime && sudo dpkg-reconfigure -f noninteractive tzdata

sudo apt install -y python-is-python3

cargo install --locked cargo-nextest

curl -fsSL https://claude.ai/install.sh | bash

curl -fsSL https://opencode.ai/install | bash

curl -sSL https://raw.githubusercontent.com/8b-is/smart-tree/main/scripts/install.sh | bash

curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | jq -r '.tag_name')/install.sh" | bash

bash -c "source ~/.nvm/nvm.sh && nvm install 24 --latest-npm --no-progress && npm install -g context-mode" || bash -c "npm install -g context-mode"

mkdir -p "${containerWorkspaceFolder}"/.github/hooks

wget https://raw.githubusercontent.com/mksglu/context-mode/refs/heads/main/configs/vscode-copilot/hooks.json -O .github/hooks/context-mode.json

sudo apt update

sudo apt install -y --no-install-recommends default-jre-headless
