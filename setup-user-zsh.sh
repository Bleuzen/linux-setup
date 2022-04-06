#!/bin/bash

cd dotfiles/

cp .p10k.zsh .zshrc .zprofile ~/

mkdir -p ~/.zsh

cd ~/.zsh/

git clone --depth=1 https://github.com/romkatv/powerlevel10k.git

git clone https://github.com/zsh-users/zsh-autosuggestions

git clone https://github.com/zsh-users/zsh-syntax-highlighting.git
