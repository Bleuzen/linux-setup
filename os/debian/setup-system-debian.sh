#!/bin/bash

if [[ $EUID -ne 0 ]];
then
    echo "This script has to be executed as root"
    exit 1
fi

PATH="$PATH:/usr/sbin"

function create_swap_file {
    fallocate -l 2G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
}

function create_encrypted_swap_file {
    fallocate -l 2G /cryptswap
    chmod 600 /cryptswap
    echo 'cryptswap /cryptswap /dev/urandom swap' >> /etc/crypttab
    echo '/dev/mapper/cryptswap none swap sw 0 0' >> /etc/fstab
}

function shorten_grub_timeouts {
    sed -i 's/^GRUB_TIMEOUT=.*$/GRUB_TIMEOUT=1\nGRUB_RECORDFAIL_TIMEOUT=1/g' /etc/default/grub
    update-grub
}

# Debian KDE comes with some packages pre-installed which I do not need
# uninstall them here to have a more minimalistic system
function cleanup_packages_kde {
    apt-get remove -y kdepim-runtime akregator apper dragonplayer juk k3b kmag kmail kmousetool kmouth knotes konqueror kontrast korganizer pim-sieve-editor sweeper xterm
    apt-get autoremove -y
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
    ACTIONS="org.freedesktop.packagekit.upgrade-system;org.freedesktop.packagekit.trigger-offline-update"
    if [[ $1 == "with_flatpak" ]]; then
        # allow flatpak updates (and app (un-)installs) (app-install permission is also needed for some updates which pull in new dependencies)
        ACTIONS="$ACTIONS;org.freedesktop.Flatpak.runtime-install;org.freedesktop.Flatpak.runtime-uninstall;org.freedesktop.Flatpak.app-install;org.freedesktop.Flatpak.app-uninstall"
    fi
    cat << EOF > /etc/polkit-1/localauthority/50-local.d/allowupdates.pkla
[Normal Staff Permissions]
#Identity=unix-group:allowupdates
Identity=unix-user:*
Action=$ACTIONS
ResultAny=no
ResultInactive=no
ResultActive=yes
EOF
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

# The current bookworm installer generates an incomplete sources list
# so a valid complete one can be recreated with this function
function rewrite_bookworm_sources_list {
        cat << EOF > /etc/apt/sources.list
deb http://deb.debian.org/debian bookworm main non-free-firmware
deb-src http://deb.debian.org/debian bookworm main non-free-firmware

deb http://deb.debian.org/debian-security/ bookworm-security main non-free-firmware
deb-src http://deb.debian.org/debian-security/ bookworm-security main non-free-firmware

deb http://deb.debian.org/debian bookworm-updates main non-free-firmware
deb-src http://deb.debian.org/debian bookworm-updates main non-free-firmware
EOF
}

function update_system {
    apt update && apt upgrade -y
}

function install_recommended_fonts {
    apt install -y fonts-recommended
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
    apt install -y flatpak plasma-discover-backend-flatpak
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
}

function allow_flatpak_read_gtk3_theme {
    flatpak override --filesystem=xdg-config/gtk-3.0/settings.ini:ro && \
    flatpak override --filesystem=xdg-config/gtk-3.0/gtk.css:ro && \
    flatpak override --filesystem=xdg-config/gtk-3.0/colors.css:ro && \
    flatpak override --filesystem=xdg-config/gtk-3.0/assets:ro
}

function install_pipewire {
    apt install -y pipewire pipewire-audio-client-libraries pipewire-pulse wireplumber
}

function install_vlc {
    apt install -y vlc
}

function install_fish_shell {
    apt install -y fish
}

function install_zsh_shell {
    apt install -y zsh
    # Optional: zsh-autosuggestions zsh-syntax-highlighting zsh-theme-powerlevel9k
}

function install_themes {
    apt install -y materia-kde materia-gtk-theme papirus-icon-theme
}

function make_python3_default {
    apt install -y python-is-python3
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
shorten_grub_timeouts
# cleanup_packages_kde
ban_snap
# allow_updates  # allow only apt updates
allow_updates with_flatpak  # allow apt and flatpak updates, gives flatpak un-/install permission to all users
# force_discover_auto_updates
# force_discover_offline_updates
# rewrite_bookworm_sources_list
update_system
install_recommended_fonts
install_plymouth  # graphical boot screen, shows update progress
install_flatpak
# allow_flatpak_read_gtk3_theme
install_pipewire
install_vlc
# install_fish_shell
# install_zsh_shell
# install_themes
make_python3_default
# setup_audio_realtime_privileges
replace_firefox_esr_with_flatpak
