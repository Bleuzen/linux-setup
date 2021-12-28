#!/bin/bash

if [[ $EUID -eq 0 ]];
then
    echo "Do not run this as root"
    exit
fi

function install_zsh_config {
    cat > /home/$USER/.zshrc <<EOF
setopt histignorealldups sharehistory

bindkey -e

HISTSIZE=1000
SAVEHIST=1000
HISTFILE=~/.zsh_history

autoload -Uz compinit
compinit

zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _complete _ignored
zstyle ':completion:*' group-name ''
zstyle ':completion:*' menu select=2
eval "\$(dircolors -b)"
zstyle ':completion:*:default' list-colors \${(s.:.)LS_COLORS}
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' verbose true

zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u \$USER -o pid,%cpu,tty,cputime,cmd'

source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
bindkey '^F' autosuggest-accept

source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

source /usr/share/powerlevel9k/powerlevel9k.zsh-theme
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir vcs)
POWERLEVEL9K_DISABLE_RPROMPT=true
EOF
}

function change_konsole_shell_zsh {
    kwriteconfig5 --file "/home/$USER/.local/share/konsole/zsh.profile" --group General --key Name --type string "zsh"
    kwriteconfig5 --file "/home/$USER/.local/share/konsole/zsh.profile" --group General --key Command --type string /usr/bin/zsh
    kwriteconfig5 --file "/home/$USER/.config/konsolerc" --group "Desktop Entry" --key "DefaultProfile" --type string "zsh.profile"
}

install_zsh_config
change_konsole_shell_zsh
