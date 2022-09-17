#!/bin/bash

if [[ $EUID -ne 0 ]];
then
    exec sudo /bin/bash "$0" "$@"
fi

function update_system {
    dnf update --refresh -y
}

function install_nvidia_driver {
    dnf install fedora-workstation-repositories
    dnf config-manager --set-enable rpmfusion-nonfree-nvidia-driver
    dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda
}

function setup_flathub {
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
}

function allow_flatpak_read_gtk3_theme {
    flatpak override --filesystem=xdg-config/gtk-3.0/settings.ini:ro && \
    flatpak override --filesystem=xdg-config/gtk-3.0/gtk.css:ro && \
    flatpak override --filesystem=xdg-config/gtk-3.0/colors.css:ro && \
    flatpak override --filesystem=xdg-config/gtk-3.0/assets:ro
}

update_system
# install_nvidia_driver
setup_flathub
# allow_flatpak_read_gtk3_theme
