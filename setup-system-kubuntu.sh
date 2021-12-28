#!/bin/bash

if [[ $EUID -ne 0 ]];
then
    exec sudo /bin/bash "$0" "$@"
fi

function disable_data_collection {
    apt purge -y ubuntu-report
}

function ban_snap {
    apt purge -y snapd
    rm -vrf /snap /var/snap /var/lib/snapd /var/cache/snapd /usr/lib/snapd
    bash -c 'cat << EOF > /etc/apt/preferences.d/nosnap.pref
Package: snapd
Pin: release a=*
Pin-Priority: -10
EOF'
}

function allow_updates {
    bash -c 'cat << EOF > /etc/polkit-1/localauthority/50-local.d/allowupdates.pkla
[Normal Staff Permissions]
#Identity=unix-group:allowupdates
Identity=unix-user:*
Action=org.freedesktop.packagekit.upgrade-system;org.freedesktop.packagekit.trigger-offline-update
ResultAny=no
ResultInactive=no
ResultActive=yes
EOF'
}

function force_discover_auto_updates {
    bash -c 'cat << EOF > /etc/xdg/PlasmaDiscoverUpdates
[Global]
UseUnattendedUpdates[\$i]=true
EOF'
    chmod o+r /etc/xdg/PlasmaDiscoverUpdates
}

function force_discover_offline_updates {
    bash -c 'cat << EOF > /etc/xdg/discoverrc
[Software]
UseOfflineUpdates[\$i]=true
EOF'
    chmod o+r /etc/xdg/discoverrc
}

function update_system {
    apt update && apt upgrade -y
}

function install_german_language_packs {
    apt install -y language-pack-de language-pack-gnome-de
    apt install -y $(check-language-support de)
}

function autoinstall_drivers {
    ubuntu-drivers install
}

function install_flatpak {
    apt install -y flatpak plasma-discover-backend-flatpak
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
}

function install_fish_shell {
    apt install -y fish
}

function install_zsh_shell {
    apt install -y zsh zsh-autosuggestions zsh-syntax-highlighting zsh-theme-powerlevel9k
}

function install_themes {
    apt install -y materia-kde materia-gtk-theme papirus-icon-theme
}

function make_python3_default {
    apt install -y python-is-python3
}

disable_data_collection
ban_snap
allow_updates
# force_discover_auto_updates
# force_discover_offline_updates
update_system
install_german_language_packs
autoinstall_drivers
install_flatpak
# install_fish_shell
install_zsh_shell
install_themes
make_python3_default
