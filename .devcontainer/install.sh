#!/bin/bash
sudo apt update && sudo apt install ansible -y
curl -fsSL https://chatgpt.com/codex/install.sh | CODEX_NON_INTERACTIVE=1 sh