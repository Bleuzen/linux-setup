#!/bin/bash

if [[ $EUID -ne 0 ]];
then
    echo "This script has to be executed as root"
    exit 1
fi

PATH="$PATH:/usr/sbin"

function create_swap_file {
    fallocate -l 4G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
}

function create_encrypted_swap_file {
    apt-get install -y systemd-cryptsetup
    fallocate -l 4G /cryptswap
    chmod 600 /cryptswap
    echo 'cryptswap /cryptswap /dev/urandom swap,cipher=aes-xts-plain64,size=512,sector-size=4096' >> /etc/crypttab
    echo '/dev/mapper/cryptswap none swap sw 0 0' >> /etc/fstab
}

# function shorten_grub_timeouts {
#     sed -i 's/^GRUB_TIMEOUT=.*$/GRUB_TIMEOUT=1\nGRUB_RECORDFAIL_TIMEOUT=1/g' /etc/default/grub
#     update-grub
# }
function custom_grub_config {
    cat << EOF > /etc/default/grub.d/custom.cfg
GRUB_DEFAULT=0
GRUB_TIMEOUT=0
GRUB_RECORDFAIL_TIMEOUT=0
GRUB_TIMEOUT_STYLE=hidden
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"
GRUB_DISABLE_OS_PROBER=true
EOF
    update-grub
}

# Debian KDE comes with some packages pre-installed which I do not need
# uninstall them here to have a more minimalistic system
function cleanup_packages_kde {
    apt-get remove -y kdepim-runtime akregator apper dragonplayer juk k3b kmag kmail kmousetool kmouth knotes konqueror kontrast korganizer pim-sieve-editor sweeper xterm
    apt-get autoremove -y
}

function ban_snap {
    apt-get purge -y snapd
    rm -vrf /snap /var/snap /var/lib/snapd /var/cache/snapd /usr/lib/snapd
    bash -c 'cat << EOF > /etc/apt/preferences.d/nosnap.pref
Package: snapd
Pin: release a=*
Pin-Priority: -10
EOF'
}

function allow_updates {
    if [[ $1 == "with_flatpak" ]]; then
        # allow flatpak updates (and app (un-)installs) (app-install permission is also needed for some updates which pull in new dependencies)
        cat << EOF > /etc/polkit-1/rules.d/_allow-updates.rules
polkit.addRule(function(action, subject) {
    if ((action.id == "org.freedesktop.packagekit.trigger-offline-update" ||
         action.id == "org.freedesktop.Flatpak.app-install" ||
         action.id == "org.freedesktop.Flatpak.runtime-install" ||
         action.id == "org.freedesktop.Flatpak.app-uninstall" ||
         action.id == "org.freedesktop.Flatpak.runtime-uninstall") &&
        subject.active == true && subject.local == true &&
        subject.isInGroup("users")) {
            return polkit.Result.YES;
    }
});
EOF
    else
        cat << EOF > /etc/polkit-1/rules.d/_allow-updates.rules
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.packagekit.trigger-offline-update" &&
        subject.active == true && subject.local == true &&
        subject.isInGroup("users")) {
            return polkit.Result.YES;
    }
});
EOF
    fi
}

function force_discover_auto_updates {
    cat <<"EOF" > /etc/xdg/PlasmaDiscoverUpdates
[Global]
UseUnattendedUpdates[$i]=true
EOF
    chmod o+r /etc/xdg/PlasmaDiscoverUpdates
}

function force_discover_offline_updates {
    cat <<"EOF" > /etc/xdg/discoverrc
[Software]
UseOfflineUpdates[$i]=true
EOF
    chmod o+r /etc/xdg/discoverrc
}

function update_system {
    apt-get update && apt-get upgrade -y
}

function install_recommended_fonts {
    apt-get install -y fonts-recommended
}

# Plymouth shows a graphical splash / boot screen
# This also makes it easier to see that (offline) updates are running, hopefully prevents users from shutting down their machine while updating
# https://wiki.debian.org/plymouth
function install_plymouth {
    apt-get install -y plymouth plymouth-themes
    # Improvement idea: check if line already contains 'splash' before adding it, probably something like: grep -vq '^GRUB_CMDLINE_LINUX_DEFAULT=.*splash.*$'
    sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/& splash/' /etc/default/grub
    update-grub
}

function install_flatpak {
    apt-get install -y flatpak plasma-discover-backend-flatpak
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
}

function allow_flatpak_read_gtk3_theme {
    flatpak override --filesystem=xdg-config/gtk-3.0/settings.ini:ro && \
    flatpak override --filesystem=xdg-config/gtk-3.0/gtk.css:ro && \
    flatpak override --filesystem=xdg-config/gtk-3.0/colors.css:ro && \
    flatpak override --filesystem=xdg-config/gtk-3.0/assets:ro
}

function install_pipewire {
    apt-get install -y pipewire pipewire-audio-client-libraries pipewire-pulse wireplumber
}

function install_vlc {
    apt-get install -y vlc
}

function install_fish_shell {
    apt-get install -y fish
}

function install_zsh_shell {
    apt-get install -y zsh
    # Optional: zsh-autosuggestions zsh-syntax-highlighting zsh-theme-powerlevel9k
}

function install_themes {
    apt-get install -y materia-kde materia-gtk-theme papirus-icon-theme
}

function make_python3_default {
    apt-get install -y python-is-python3
}

function setup_audio_realtime_privileges {
    # Extracted from package: jackd2
    cat <<"EOF" > /etc/security/limits.d/99-realtime-privileges.conf
# Provided by the jackd package.
#
# Changes to this file will be preserved.
#
# If you want to enable/disable realtime permissions, run
#
#    dpkg-reconfigure -p high jackd2

@audio   -  rtprio     95
@audio   -  memlock    unlimited
#@audio   -  nice      -19
EOF
}

function replace_firefox_esr_with_flatpak {
    apt-get remove -y firefox-esr
    apt-get autoremove -y
    flatpak install -y flathub org.mozilla.firefox
}

# create_swap_file  # unencrypted swap
# create_encrypted_swap_file
custom_grub_config
# cleanup_packages_kde
ban_snap
# allow_updates  # allow only apt-get updates
allow_updates with_flatpak  # allow apt-get and flatpak updates, gives flatpak un-/install permission to all users
# force_discover_auto_updates
# force_discover_offline_updates
update_system
install_recommended_fonts
# install_plymouth  # graphical boot screen, shows update progress
install_flatpak
# allow_flatpak_read_gtk3_theme
# install_pipewire
# install_vlc
# install_fish_shell
# install_zsh_shell
# install_themes
# make_python3_default
# setup_audio_realtime_privileges
replace_firefox_esr_with_flatpak
