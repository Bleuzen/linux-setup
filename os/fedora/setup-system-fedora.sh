#!/bin/bash

if [[ $EUID -ne 0 ]];
then
    exec sudo /bin/bash "$0" "$@"
fi

function dnf_config_defaultyes {
    echo "defaultyes=True" >> /etc/dnf/dnf.conf
}

function dnf_config_disable_install_weak_deps {
    echo "install_weak_deps=False" >> /etc/dnf/dnf.conf
}

function packages_cleanup {
    dnf remove -y mariadb kmail kontact kmahjongg kmag kmines kamera kamoso dragon cryfs
}

function update_system {
    dnf update --refresh -y
}

function install_nvidia_driver {
    dnf install fedora-workstation-repositories
    dnf config-manager --set-enable rpmfusion-nonfree-nvidia-driver
    dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda
}

function enable_rpmfusion {
    dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
    dnf groupupdate -y core
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

dnf_config_defaultyes
dnf_config_disable_install_weak_deps
packages_cleanup
update_system
# install_nvidia_driver
# enable_rpmfusion
setup_flathub
# allow_flatpak_read_gtk3_theme