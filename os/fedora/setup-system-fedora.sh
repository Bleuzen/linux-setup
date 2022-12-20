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

function dnf_config_speedup {
    echo "max_parallel_downloads=5" >> /etc/dnf/dnf.conf
    echo "fastestmirror=True" >> /etc/dnf/dnf.conf
}

function packages_cleanup {
    dnf remove -y mariadb
}

function packages_cleanup_kde {
    dnf remove -y kmail kontact kmahjongg kmag kmines kamera kamoso dragon plasma-vault korganizer akonadi-import-wizard
}

function packages_cleanup_gnome {
    dnf remove -y gnome-boxes
}

function update_system {
    dnf update --refresh -y
}

function enable_nvidia_filtered_rpmfusion {
    dnf install fedora-workstation-repositories
    dnf config-manager --set-enable rpmfusion-nonfree-nvidia-driver
}

function enable_rpmfusion {
    dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
    dnf groupupdate -y core
}

function install_nvidia_driver {
    dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda
}

function rpmfusion_install_additional_codecs {
    # Source: https://rpmfusion.org/Howto/Multimedia
    dnf groupupdate multimedia --setop="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin --allowerasing -y
    dnf groupupdate sound-and-video -y
}

function rpmfusion_enable_hardware_codecs_intel_recent {
    dnf install -y intel-media-driver
}

function rpmfusion_enable_hardware_codecs_intel_older {
    dnf install -y libva-intel-driver
}

function rpmfusion_enable_hardware_codecs_amd {
    dnf swap -y mesa-va-drivers mesa-va-drivers-freeworld
    dnf swap -y mesa-vdpau-drivers mesa-vdpau-drivers-freeworld
}

function rpmfusion_enable_hardware_codecs_amd_i686 {
    # If using i686 compat libraries (for steam or alikes)
    dnf swap -y mesa-va-drivers.i686 mesa-va-drivers-freeworld.i686
    dnf swap -y mesa-vdpau-drivers.i686 mesa-vdpau-drivers-freeworld.i686
}

function rpmfusion_enable_hardware_codecs_nvidia {
    dnf install -y nvidia-vaapi-driver
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
# dnf_config_disable_install_weak_deps
dnf_config_speedup
# packages_cleanup
# packages_cleanup_kde
# packages_cleanup_gnome
update_system
# enable_nvidia_filtered_rpmfusion
enable_rpmfusion
# install_nvidia_driver
rpmfusion_install_additional_codecs
# rpmfusion_enable_hardware_codecs_intel_recent
# rpmfusion_enable_hardware_codecs_intel_older
# rpmfusion_enable_hardware_codecs_amd
# rpmfusion_enable_hardware_codecs_amd_i686
# rpmfusion_enable_hardware_codecs_nvidia
setup_flathub
# allow_flatpak_read_gtk3_theme
