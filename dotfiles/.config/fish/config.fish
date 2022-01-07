if status is-interactive
    # Commands to run in interactive sessions can go here
end

set -U fish_greeting

set PATH $PATH /home/$USER/bin

# Page up and down keys search through the history
bind -k ppage history-search-backward
bind -k npage history-search-forward
