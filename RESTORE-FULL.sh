#!/bin/bash
# Script de recuperación COMPLETA de Pi-Linux
# Ejecutar: bash RESTORE-FULL.sh

set -e

echo "=============================================="
echo "  🔧 RESTAURACIÓN COMPLETA DE PI-LINUX"
echo "=============================================="
echo ""

INSTALL_DIR="$HOME/pi-linux"
MODULES_SETUP="$HOME/www/pi_linux/modules-setup.sh"
DEPLOY_SCRIPT="$HOME/www/pi_linux/deploy-pi-linux.sh"

# ============================================
# VERIFICAR FUENTES
# ============================================

if [[ ! -f "$MODULES_SETUP" ]]; then
    echo "❌ No se encontró: $MODULES_SETUP"
    exit 1
fi

if [[ ! -f "$DEPLOY_SCRIPT" ]]; then
    echo "❌ No se encontró: $DEPLOY_SCRIPT"
    exit 1
fi

echo "📂 Fuentes encontradas:"
echo "   - $MODULES_SETUP"
echo "   - $DEPLOY_SCRIPT"
echo ""

# ============================================
# CREAR ESTRUCTURA
# ============================================

echo "📁 Creando estructura de directorios..."
mkdir -p "$INSTALL_DIR"/{modules,config,scripts,themes}
echo "   ✓ Directorios creados"
echo ""

# ============================================
# EXTRAER MÓDULOS 02-06
# ============================================

echo "🔨 Extrayendo módulos de modules-setup.sh..."

# Usar awk para extraer entre marcadores
awk '/MÓDULO 02: GPU/,/^EOF$/' "$MODULES_SETUP" | head -n -1 | tail -n +2 > "$INSTALL_DIR/modules/02-gpu.sh"
awk '/MÓDULO 03: Desktop/,/^EOF$/' "$MODULES_SETUP" | head -n -1 | tail -n +2 > "$INSTALL_DIR/modules/03-desktop.sh"
awk '/MÓDULO 04: Temas/,/^EOF$/' "$MODULES_SETUP" | head -n -1 | tail -n +2 > "$INSTALL_DIR/modules/04-themes.sh"
awk '/MÓDULO 05: Software/,/^EOF$/' "$MODULES_SETUP" | head -n -1 | tail -n +2 > "$INSTALL_DIR/modules/05-software.sh"
awk '/MÓDULO 06: Dotfiles/,/^EOF$/' "$MODULES_SETUP" | head -n -1 | tail -n +2 > "$INSTALL_DIR/modules/06-dotfiles.sh"

for i in 02 03 04 05 06; do
    chmod +x "$INSTALL_DIR/modules/$i-"*.sh
    echo "   ✓ modules/$i-*.sh"
done

# ============================================
# CREAR MÓDULOS 00 Y 01 (Básicos)
# ============================================

echo ""
echo "🔨 Creando módulos base..."

cat > "$INSTALL_DIR/modules/00-preinstall.sh" << 'EOF'
#!/bin/bash
# Módulo 00: Pre-instalación
set -e
echo "[00] Actualizando sistema..."
pacman -Syu --noconfirm
echo "[✓] Sistema actualizado"
EOF

cat > "$INSTALL_DIR/modules/01-base.sh" << 'EOF'
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
EOF

chmod +x "$INSTALL_DIR/modules/00-preinstall.sh" "$INSTALL_DIR/modules/01-base.sh"
echo "   ✓ modules/00-preinstall.sh"
echo "   ✓ modules/01-base.sh"

# ============================================
# ELIMINAR DUPLICADO
# ============================================

if [[ -f "$INSTALL_DIR/modules/04-software.sh" ]] && [[ $(wc -l < "$INSTALL_DIR/modules/04-software.sh" 2>/dev/null || echo 0) -lt 20 ]]; then
    rm -f "$INSTALL_DIR/modules/04-software.sh"
    echo "   ✓ Archivo duplicado eliminado"
fi

# ============================================
# EXTRAER CONFIGS Y SCRIPTS
# ============================================

echo ""
echo "🔨 Extrayendo configuraciones..."

# Configuración desatendida
awk '/cat > \$INSTALL_DIR\/config\/unattended.conf/,/^CONFEOF$/' "$DEPLOY_SCRIPT" | head -n -1 | tail -n +2 > "$INSTALL_DIR/config/unattended.conf"
echo "   ✓ config/unattended.conf"

# GUI script  
awk '/cat > \$INSTALL_DIR\/scripts\/gui.sh/,/^GUIEOF$/' "$DEPLOY_SCRIPT" | head -n -1 | tail -n +2 > "$INSTALL_DIR/scripts/gui.sh"
chmod +x "$INSTALL_DIR/scripts/gui.sh"
echo "   ✓ scripts/gui.sh"

# ============================================
# CREAR PI-LINUX.SH PRINCIPAL
# ============================================

echo ""
echo "🔨 Creando pi-linux.sh principal..."

cat > "$INSTALL_DIR/pi-linux.sh" << 'EOF'
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
EOF

chmod +x "$INSTALL_DIR/pi-linux.sh"
echo "   ✓ pi-linux.sh"

# ============================================
# RESUMEN
# ============================================

echo ""
echo "=============================================="
echo "  ✅ RESTAURACIÓN COMPLETA"
echo "=============================================="
echo ""
echo "📂 Archivos restaurados en: $INSTALL_DIR"
echo ""
echo "📁 Módulos:"
ls -1 "$INSTALL_DIR/modules/"
echo ""
echo "📁 Configuraciones:"
ls -1 "$INSTALL_DIR/config/"
echo ""
echo "📁 Scripts:"
ls -1 "$INSTALL_DIR/scripts/"
echo ""
echo "🚀 Próximos pasos:"
echo "   cd $INSTALL_DIR"
echo "   ./pi-linux.sh --help"
echo ""
