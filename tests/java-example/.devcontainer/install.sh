#!/bin/bash

# This template provides a paved road for wrapping all devcontainer installers.

# For example, to install claude-code CLI in every devcontainer, use:
curl -fsSL https://claude.ai/install.sh | bash

# And Codex: 
export CODEX_NON_INTERACTIVE=true
curl -fsSL https://chatgpt.com/codex/install.sh | sh

curl -sL -o cfr.jar 'https://www.benf.org/other/cfr/cfr-0.152.jar'
