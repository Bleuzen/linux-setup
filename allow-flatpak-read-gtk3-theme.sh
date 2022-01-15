#!/bin/bash

if [[ $EUID -ne 0 ]];
then
    flatpak override --filesystem=xdg-config/gtk-3.0/settings.ini:ro && \
    flatpak override --filesystem=xdg-config/gtk-3.0/gtk.css:ro && \
    flatpak override --filesystem=xdg-config/gtk-3.0/colors.css:ro && \
    flatpak override --filesystem=xdg-config/gtk-3.0/assets:ro
else
    flatpak override --user --filesystem=xdg-config/gtk-3.0/settings.ini:ro && \
    flatpak override --user --filesystem=xdg-config/gtk-3.0/gtk.css:ro && \
    flatpak override --user --filesystem=xdg-config/gtk-3.0/colors.css:ro && \
    flatpak override --user --filesystem=xdg-config/gtk-3.0/assets:ro
fi
