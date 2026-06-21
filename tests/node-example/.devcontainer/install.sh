#!/bin/bash
set -euo pipefail

DEVCONTAINER_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
containerWorkspaceFolder="$(dirname -- "$DEVCONTAINER_DIR")"
export containerWorkspaceFolder

sudo apt update && sudo apt install -y ripgrep ncat

sudo ln -sf /usr/share/zoneinfo/America/Chicago /etc/localtime && sudo dpkg-reconfigure -f noninteractive tzdata

sudo apt update && sudo apt install -y npm --no-install-recommends

npm install

curl -fsSL https://chatgpt.com/codex/install.sh | CODEX_NON_INTERACTIVE=1 sh

curl -fsSL https://claude.ai/install.sh | bash
