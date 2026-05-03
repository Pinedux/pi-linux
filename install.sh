#!/bin/bash
# Pi-Linux Remote Installer
# Punto de entrada para: bash <(curl -sL https://raw.githubusercontent.com/Pinedux/pi-linux/main/install.sh)

set -e

REPO_URL="https://github.com/Pinedux/pi-linux.git"
INSTALL_DIR="/tmp/pi-linux-$$"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()    { echo -e "${CYAN}ℹ${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warning() { echo -e "${YELLOW}⚠${NC} $1"; }
error()   { echo -e "${RED}✗${NC} $1"; }

# Verificar que estamos en Arch Linux
if [[ ! -f /etc/arch-release ]]; then
    error "Este instalador solo funciona en Arch Linux."
    exit 1
fi

# Verificar conexion
info "Verificando conexion a internet..."
if ! ping -c 1 github.com &>/dev/null; then
    error "No hay conexion a internet."
    exit 1
fi
success "Conexion OK"

# Limpiar instalacion previa si existe
if [[ -d "$INSTALL_DIR" ]]; then
    rm -rf "$INSTALL_DIR"
fi

# Clonar repo
info "Descargando Pi-Linux desde GitHub..."
if ! git clone --depth 1 "$REPO_URL" "$INSTALL_DIR" 2>/dev/null; then
    error "No se pudo clonar el repositorio."
    exit 1
fi
success "Pi-Linux descargado en $INSTALL_DIR"

# Ejecutar instalador principal
cd "$INSTALL_DIR"
exec bash ./pi-linux.sh "$@"
