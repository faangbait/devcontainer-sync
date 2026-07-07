#!/bin/bash
set -euo pipefail

DEVCONTAINER_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
containerWorkspaceFolder="$(dirname -- "$DEVCONTAINER_DIR")"
export containerWorkspaceFolder

sudo apt update && sudo apt install -y ripgrep ncat

sudo ln -sf /usr/share/zoneinfo/America/Chicago /etc/localtime && sudo dpkg-reconfigure -f noninteractive tzdata

if [ -f "${containerWorkspaceFolder}/requirements.txt" ] || [ -f "${containerWorkspaceFolder}/dev_requirements.txt" ]; then
  set --
  [ -f "${containerWorkspaceFolder}/requirements.txt" ] && set -- "$@" -r "${containerWorkspaceFolder}/requirements.txt"
  [ -f "${containerWorkspaceFolder}/dev_requirements.txt" ] && set -- "$@" -r "${containerWorkspaceFolder}/dev_requirements.txt"
  pip install "$@"
fi

curl -fsSL https://claude.ai/install.sh | bash

curl -fsSL https://opencode.ai/install | bash

curl -sSL https://raw.githubusercontent.com/8b-is/smart-tree/main/scripts/install.sh | bash

curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | jq -r '.tag_name')/install.sh" | bash

bash -c "source ~/.nvm/nvm.sh && nvm install 24 --latest-npm --no-progress && npm install -g context-mode" || bash -c "npm install -g context-mode"

mkdir -p "${containerWorkspaceFolder}"/.github/hooks

wget https://raw.githubusercontent.com/mksglu/context-mode/refs/heads/main/configs/vscode-copilot/hooks.json -O .github/hooks/context-mode.json

mkdir -p ~/.ssh

printf 'Host *\n  User ec2-user\n  IdentityFile %s/.ssh/id_rsa\n  StrictHostKeyChecking no\n' "${containerWorkspaceFolder}" > ~/.ssh/config

bash "${containerWorkspaceFolder}/.devcontainer/aws_configure.sh"

sudo apt update

sudo apt install -y --no-install-recommends ansible
