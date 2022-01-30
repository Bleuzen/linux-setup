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

function periodically_mark_kernels_auto_installed {
    # Kernels installed by Discover / PackageKit are currently always marked as installed manually, even if they got installed by an update
    # This leads to apt never auto removing old kernels and will eventually cause the /boot partition to run out of space.
    # As a workaround: periodically mark all installed kernels as installed automatically for now
    # See: https://github.com/PackageKit/PackageKit/issues/450
    cat <<"EOF" > /etc/cron.weekly/mark-kernels-auto-installed
#!/bin/sh
apt-mark auto $(apt-mark showmanual | grep -E "^linux-([[:alpha:]]+-)+[[:digit:].]+-[^-]+(|-.+)$")
EOF
    chmod 755 /etc/cron.weekly/mark-kernels-auto-installed
}

function allow_updates {
    cat <<"EOF" > /etc/polkit-1/localauthority/50-local.d/allowupdates.pkla
[Normal Staff Permissions]
#Identity=unix-group:allowupdates
Identity=unix-user:*
Action=org.freedesktop.packagekit.upgrade-system;org.freedesktop.packagekit.trigger-offline-update
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

function allow_flatpak_read_gtk3_theme {
    flatpak override --filesystem=xdg-config/gtk-3.0/settings.ini:ro && \
    flatpak override --filesystem=xdg-config/gtk-3.0/gtk.css:ro && \
    flatpak override --filesystem=xdg-config/gtk-3.0/colors.css:ro && \
    flatpak override --filesystem=xdg-config/gtk-3.0/assets:ro
}

function install_pipewire {
    apt install -y pipewire pipewire-audio-client-libraries pipewire-pulse wireplumber
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

disable_data_collection
ban_snap
periodically_mark_kernels_auto_installed
allow_updates
# force_discover_auto_updates
# force_discover_offline_updates
update_system
install_german_language_packs
autoinstall_drivers
install_flatpak
# allow_flatpak_read_gtk3_theme
install_pipewire
install_fish_shell
# install_zsh_shell
# install_themes
make_python3_default
# setup_audio_realtime_privileges
