#!/bin/bash
# Pi-Linux - Arch Linux Post-Install Script
# https://github.com/TU_USUARIO/pi-linux

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="$SCRIPT_DIR/modules"
CONFIG_DIR="$SCRIPT_DIR/config"
VERSION="1.0.0"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'

print_banner() {
    clear
    echo -e "${MAGENTA}"
    echo "    ____  _       __    _           __  _"
    echo "   / __ \(_)___ _/ /_  (_)_________/ /_(_)___  ___"
    echo "  / /_/ / / __ '/ __ \/ / ___/ ___/ __/ / __ \/ _ \\"
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
        echo -e "${RED}✗${NC} Este script debe ejecutarse como root"
        exit 1
    fi
}

check_arch() {
    if [[ ! -f /etc/arch-release ]]; then
        echo -e "${RED}✗${NC} Este instalador solo funciona en Arch Linux"
        exit 1
    fi
}

check_connection() {
    echo -e "${CYAN}ℹ${NC} Verificando conexión..."
    if ! ping -c 1 archlinux.org &>/dev/null; then
        echo -e "${RED}✗${NC} No hay conexión a internet"
        exit 1
    fi
    echo -e "${GREEN}✓${NC} Conexión OK"
}

show_menu() {
    echo -e "${BOLD}Modo de Instalación:${NC}"
    echo ""
    echo -e "  ${CYAN}1)${NC} Modo Interactivo (recomendado)"
    echo -e "  ${CYAN}2)${NC} Modo Automático (KDE Plasma)"
    echo ""
    echo -e "  ${RED}0)${NC} Salir"
    echo ""
}

select_de() {
    echo ""
    echo -e "${BOLD}Entorno de Escritorio:${NC}"
    echo ""
    echo -e "  ${CYAN}1)${NC} KDE Plasma"
    echo -e "  ${CYAN}2)${NC} GNOME"
    echo -e "  ${CYAN}3)${NC} Hyprland"
    echo ""
    read -rp "Selecciona [1-3]: " de
    case $de in
        1) DESKTOP_ENV="plasma" ;;
        2) DESKTOP_ENV="gnome" ;;
        3) DESKTOP_ENV="hyprland" ;;
        *) DESKTOP_ENV="plasma" ;;
    esac
    export DESKTOP_ENV
    echo -e "${GREEN}✓${NC} DE: ${BOLD}$DESKTOP_ENV${NC}"
}

select_gpu() {
    echo ""
    echo -e "${BOLD}Detección GPU:${NC}"
    if lspci | grep -i nvidia &>/dev/null; then
        GPU_TYPE="nvidia"
        echo "Detectada: NVIDIA"
    elif lspci | grep -i amd &>/dev/null; then
        GPU_TYPE="amd"
        echo "Detectada: AMD"
    elif lspci | grep -i intel &>/dev/null; then
        GPU_TYPE="intel"
        echo "Detectada: Intel"
    else
        GPU_TYPE="generic"
    fi
    export GPU_TYPE
}

load_unattended() {
    if [[ -f "$CONFIG_DIR/unattended.conf" ]]; then
        source "$CONFIG_DIR/unattended.conf"
    else
        DESKTOP_ENV="plasma"
        GPU_TYPE="auto"
    fi
}

run_modules() {
    for module in "$MODULES_DIR"/*.sh; do
        if [[ -f "$module" ]]; then
            echo ""
            echo -e "${CYAN}▶ $(basename $module)${NC}"
            bash "$module"
        fi
    done
}

main() {
    check_root
    check_arch
    print_banner
    check_connection
    
    # Argumentos
    if [[ "$1" == "--unattended" ]]; then
        load_unattended
        echo -e "${CYAN}ℹ${NC} Modo automático"
    else
        show_menu
        read -rp "Selecciona [0-2]: " choice
        case $choice in
            1) select_de; select_gpu ;;
            2) load_unattended ;;
            0) exit 0 ;;
        esac
    fi
    
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "  DE: $DESKTOP_ENV"
    echo "  GPU: $GPU_TYPE"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -rp "¿Iniciar? [S/n]: " confirm
    [[ "$confirm" == "n" ]] && exit 0
    
    run_modules
    
    echo ""
    echo -e "${GREEN}✓ Instalación completada!${NC}"
    read -rp "¿Reiniciar? [s/N]: " reboot
    [[ "$reboot" == "s" ]] && reboot
}

main "$@"
