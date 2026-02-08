#!/bin/bash
# Pi-Linux One-Line Installer
# curl -fsSL https://raw.githubusercontent.com/Pinedux/pi-linux/main/install.sh | sudo bash

set -e

REPO_URL="https://github.com/Pinedux/pi-linux"
INSTALL_DIR="/tmp/pi-linux-$$"

echo "🥧 Pi-Linux Installer"
echo "====================="
echo ""

# Verificar root
if [[ $EUID -ne 0 ]]; then
    echo "❌ Este script debe ejecutarse como root"
    echo "   Usa: curl -fsSL ... | sudo bash"
    exit 1
fi

# Verificar Arch
if [[ ! -f /etc/arch-release ]]; then
    echo "❌ Este instalador solo funciona en Arch Linux"
    exit 1
fi

echo "[*] Descargando Pi-Linux..."

# Instalar git si no existe
if ! command -v git &>/dev/null; then
    pacman -Sy --needed --noconfirm git
fi

# Clonar repositorio
rm -rf "$INSTALL_DIR"
git clone --depth 1 "$REPO_URL.git" "$INSTALL_DIR"

echo "[*] Iniciando instalador..."
cd "$INSTALL_DIR"

# Ejecutar instalador principal
exec bash pi-linux.sh
