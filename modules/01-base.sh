#!/bin/bash
# Módulo 01: Sistema base
set -e
echo "[01] Instalando sistema base..."
pacman -S --needed --noconfirm \
    networkmanager git wget curl base-devel \
    bluez bluez-utils pulseaudio pipewire
systemctl enable NetworkManager
systemctl enable bluetooth
echo "[✓] Base instalada"
