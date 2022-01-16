#!/bin/bash

if [[ $EUID -eq 0 ]];
then
    echo "Do not run this as root"
    exit
fi

if [ -d "$HOME/.config/fish" ]; then
    echo "Fish config dir already exists, deleting it..."
    rm -r "$HOME/.config/fish"
fi

cp -r dotfiles/.config/fish $HOME/.config/
