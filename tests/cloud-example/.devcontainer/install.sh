#!/bin/bash
set -euo pipefail

DEVCONTAINER_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
containerWorkspaceFolder="$(dirname -- "$DEVCONTAINER_DIR")"
export containerWorkspaceFolder

sudo apt update && sudo apt install -y ripgrep ncat

sudo ln -sf /usr/share/zoneinfo/America/Chicago /etc/localtime && sudo dpkg-reconfigure -f noninteractive tzdata

echo alias tf=terraform > ~/.bash_aliases

curl -fsSL https://chatgpt.com/codex/install.sh | CODEX_NON_INTERACTIVE=1 sh

curl -fsSL https://claude.ai/install.sh | bash

curl -fsSL https://opencode.ai/install | bash

mkdir -p ~/.ssh

printf 'Host *\n  User ec2-user\n  IdentityFile %s/.ssh/id_rsa\n  StrictHostKeyChecking no\n' "${containerWorkspaceFolder}" > ~/.ssh/config

bash "${containerWorkspaceFolder}/.devcontainer/aws_configure.sh"
