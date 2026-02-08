#!/bin/bash
set -e
echo "[00] Actualizando sistema..."
pacman -Syu --noconfirm
echo "[✓] Sistema actualizado"
