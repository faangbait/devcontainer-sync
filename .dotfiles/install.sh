#!/bin/bash
ln -sf "$(pwd)/.gitconfig" "$HOME/.gitconfig"
ln -sf "$(pwd)/.gitignore_global" "$HOME/.gitignore_global"

echo "Dotfiles successfully installed!"