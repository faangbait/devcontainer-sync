#!/bin/bash

set -euo pipefail

DEVCONTAINER_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
containerWorkspaceFolder="$(dirname -- "$DEVCONTAINER_DIR")"
export containerWorkspaceFolder

sudo apt update && sudo apt install ansible shellcheck -y
curl -fsSL https://claude.ai/install.sh | bash
curl -fsSL https://opencode.ai/install | bash
curl -sSL https://raw.githubusercontent.com/8b-is/smart-tree/main/scripts/install.sh | bash
bash -c "source /usr/local/share/nvm/nvm.sh && nvm install 24 --latest-npm --no-progress"
