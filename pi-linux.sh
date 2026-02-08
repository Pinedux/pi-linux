#!/bin/bash
# Pi-Linux - Arch Linux Post-Install Script
# https://github.com/Pinedux/pi-linux

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="$SCRIPT_DIR/modules"
CONFIG_DIR="$SCRIPT_DIR/config"
VERSION="1.1.0"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'

info() { echo -e "${BLUE}ℹ${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warning() { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; }

print_banner() {
    clear
    echo -e "${MAGENTA}"
    echo "    ____  _       __    _           __  _"
    echo "   / __ \\(_)___ _/ /_  (_)_________/ /_(_)___  ___"
    echo "  / /_/ / / __ '/ __ \\/ / ___/ ___/ __/ / __ \\/ \\\\"
    echo " / ____/ / /_/ / / / / (__  |__  ) /_/ / / / /  __/"
    echo "/_/   /_/\\__, /_/ /_/_/____/____/\\__/_/_/ /_/\\___/"
    echo "        /____/"
    echo -e "${NC}"
    echo -e "${CYAN}    Arch Linux Post-Install Script v${VERSION}${NC}"
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "Este script debe ejecutarse como root"
        exit 1
    fi
}

check_arch() {
    if [[ ! -f /etc/arch-release ]]; then
        error "Este instalador solo funciona en Arch Linux"
        exit 1
    fi
}

show_menu() {
    echo -e "${BOLD}Modo de Instalación:${NC}"
    echo ""
    echo -e "  ${CYAN}1)${NC} Modo Interactivo"
    echo -e "  ${CYAN}2)${NC} Modo Automático"
    echo -e "  ${CYAN}3)${NC} Modo GUI"
    echo -e "  ${RED}0)${NC} Salir"
    echo ""
}

load_unattended() {
    if [[ -f "$CONFIG_DIR/unattended.conf" ]]; then
        source "$CONFIG_DIR/unattended.conf"
    else
        DESKTOP_ENV="plasma"
        GPU_TYPE="auto"
        THEME="none"
    fi
}

run_modules() {
    for module in "$MODULES_DIR"/*.sh; do
        if [[ -f "$module" ]]; then
            echo ""
            echo -e "${CYAN}▶ $(basename "$module")${NC}"
            bash "$module"
        fi
    done
}

main() {
    check_root
    check_arch
    print_banner
    
    if [[ "$1" == "--unattended" ]]; then
        load_unattended
        info "Modo automático"
    else
        show_menu
        read -rp "Selecciona [0-3]: " choice
        case $choice in
            1) read -rp "DE (plasma/gnome/hyprland): " DESKTOP_ENV ;;
            2) load_unattended ;;
            3) source "$SCRIPT_DIR/scripts/gui.sh" && run_gui_mode ;;
            0) exit 0 ;;
        esac
    fi
    
    echo ""
    echo "DE: $DESKTOP_ENV | GPU: $GPU_TYPE | Tema: $THEME"
    read -rp "¿Iniciar? [S/n]: " confirm
    [[ "$confirm" == "n" ]] && exit 0
    
    run_modules
    
    echo ""
    success "¡Instalación completada!"
}

main "$@"
