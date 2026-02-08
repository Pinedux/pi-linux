#!/bin/bash
# Módulo 00: Pre-instalación
set -e
echo "[00] Actualizando sistema..."
pacman -Syu --noconfirm
echo "[✓] Sistema actualizado"
