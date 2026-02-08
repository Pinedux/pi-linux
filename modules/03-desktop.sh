#!/bin/bash
set -e
DESKTOP_ENV="${DESKTOP_ENV:-plasma}"
echo "[03] DE: $DESKTOP_ENV"
case "$DESKTOP_ENV" in
    plasma)
        pacman -S --needed --noconfirm plasma-meta kde-applications sddm
        systemctl enable sddm
        ;;
    gnome)
        pacman -S --needed --noconfirm gnome gnome-extra gdm
        systemctl enable gdm
        ;;
    hyprland)
        pacman -S --needed --noconfirm hyprland waybar wofi kitty
        ;;
esac
echo "[✓] DE instalado"
