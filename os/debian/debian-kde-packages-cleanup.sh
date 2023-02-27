#!/bin/bash

if [[ $EUID -ne 0 ]];
then
    echo "This script has to be executed as root"
    exit 1
fi


# Debian KDE comes with some packages pre-installed which I do not need
# uninstall them here to have a more minimalistic system
function cleanup_packages_kde {
    apt-get remove -y akregator apper dragonplayer juk k3b kmag kmail kmousetool kmouth knotes konqueror kontrast korganizer kwrite pim-sieve-editor sweeper xterm
}

cleanup_packages_kde
