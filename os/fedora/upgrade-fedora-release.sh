#!/bin/bash

if [[ $EUID -ne 0 ]];
then
    exec sudo /bin/bash "$0" "$@"
fi

# TODO: get next releasever automatically or as a parameter to this script

dnf upgrade --refresh
dnf install -y dnf-plugin-system-upgrade
dnf system-upgrade download --releasever=37

# dnf distro-sync -y
