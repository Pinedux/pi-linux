#!/bin/bash
set -e
echo "[01] Instalando base..."
pacman -S --needed --noconfirm \
    base-devel git curl wget \
    networkmanager pipewire \
    noto-fonts papirus-icon-theme
systemctl enable NetworkManager
echo "[✓] Base instalada"
