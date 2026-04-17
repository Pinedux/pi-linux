#!/bin/bash
# Pi-Linux Common Library v2.0
# Funciones helper compartidas entre todos los módulos

set -e

# ============================================
# COLORES Y FORMATO
# ============================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'

info()    { echo -e "${CYAN}ℹ${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warning() { echo -e "${YELLOW}⚠${NC} $1"; }
error()   { echo -e "${RED}✗${NC} $1"; }

banner() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}$1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# ============================================
# USUARIO Y RUTAS
# ============================================

# Detectar usuario real (aunque se ejecute con sudo)
PI_REAL_USER="${SUDO_USER:-$USER}"
PI_USER_HOME="$(eval echo ~"$PI_REAL_USER")"
PI_CONFIG_DIR="${PI_USER_HOME}/.config"

# ============================================
# UTILIDADES
# ============================================

is_yes() {
    local val="${1:-n}"
    case "$val" in
        y|Y|s|S|yes|YES|true|1)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# ============================================
# LOGGING
# ============================================

PI_LOG_FILE="${PI_LOG_FILE:-/tmp/pi-linux-$(date +%Y%m%d-%H%M%S).log}"

log_cmd() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$PI_LOG_FILE"
}

# ============================================
# AUR / YAY
# ============================================

ensure_yay() {
    if command -v yay &>/dev/null; then
        return 0
    fi
    info "Instalando yay (AUR helper)..."
    local tmpdir
    tmpdir=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git --depth=1 "$tmpdir/yay"
    chown -R "${PI_REAL_USER}:${PI_REAL_USER}" "$tmpdir/yay"
    (
        cd "$tmpdir/yay"
        sudo -u "${PI_REAL_USER}" makepkg -si --noconfirm
    )
    rm -rf "$tmpdir"
    success "yay instalado"
}

install_aur() {
    ensure_yay
    sudo -u "${PI_REAL_USER}" yay -S --needed --noconfirm "$@" 2>/dev/null || {
        warning "Falló la instalación AUR de: $*"
        return 1
    }
}

# ============================================
# PACMAN WRAPPER
# ============================================

install_pkg() {
    pacman -S --needed --noconfirm "$@" 2>/dev/null || {
        warning "Algunos paquetes no se instalaron: $*"
        return 1
    }
}

# ============================================
# GNOME HELPERS
# ============================================

gnome_install_extension() {
    local uuid="$1"
    local name="$2"
    info "Instalando extensión GNOME: $name"
    
    # Intentar via pacman primero (algunas están empaquetadas)
    if pacman -S --needed --noconfirm "gnome-shell-extension-${name,,}" 2>/dev/null; then
        success "Extensión $name instalada desde repos"
        return 0
    fi
    
    # Fallback: descargar desde extensions.gnome.org via busctl
    # Nota: gnome-extensions CLI puede instalar desde zip
    warning "Extensión $name no disponible en repos. Se omite (instalar manualmente)."
}

gnome_set_theme() {
    local gtk_theme="$1"
    local icon_theme="$2"
    local cursor_theme="${3:-Bibata-Modern-Ice}"
    local shell_theme="${4:-}"
    
    info "Aplicando tema GNOME: $gtk_theme"
    
    sudo -u "${PI_REAL_USER}" DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u "$PI_REAL_USER")/bus \
        gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme" 2>/dev/null || true
    
    sudo -u "${PI_REAL_USER}" DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u "$PI_REAL_USER")/bus \
        gsettings set org.gnome.desktop.interface icon-theme "$icon_theme" 2>/dev/null || true
    
    sudo -u "${PI_REAL_USER}" DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u "$PI_REAL_USER")/bus \
        gsettings set org.gnome.desktop.interface cursor-theme "$cursor_theme" 2>/dev/null || true
    
    if [[ -n "$shell_theme" ]]; then
        sudo -u "${PI_REAL_USER}" DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u "$PI_REAL_USER")/bus \
            gsettings set org.gnome.shell.extensions.user-theme name "$shell_theme" 2>/dev/null || true
    fi
    
    success "Tema GNOME aplicado"
}

# ============================================
# PLASMA HELPERS
# ============================================

plasma_apply_global_theme() {
    local theme_name="$1"
    info "Aplicando Global Theme Plasma: $theme_name"
    
    # lookandfeeltool aplica el tema completo
    sudo -u "${PI_REAL_USER}" lookandfeeltool -a "$theme_name" 2>/dev/null || {
        warning "No se pudo aplicar Global Theme: $theme_name"
        return 1
    }
    success "Global Theme aplicado"
}

plasma_apply_color_scheme() {
    local scheme="$1"
    info "Aplicando esquema de color: $scheme"
    sudo -u "${PI_REAL_USER}" plasma-apply-colorscheme "$scheme" 2>/dev/null || true
}

plasma_apply_widget_style() {
    local style="$1"
    info "Aplicando estilo de widgets: $style"
    sudo -u "${PI_REAL_USER}" plasma-apply-desktoptheme "$style" 2>/dev/null || true
}

# ============================================
# SDDM HELPERS
# ============================================

sddm_set_theme() {
    local theme_name="$1"
    info "Configurando tema SDDM: $theme_name"
    
    mkdir -p /etc/sddm.conf.d
    cat > /etc/sddm.conf.d/theme.conf <<EOF
[Theme]
Current=${theme_name}
EOF
    success "Tema SDDM configurado"
}

sddm_enable() {
    info "Habilitando SDDM..."
    systemctl enable sddm
    success "SDDM habilitado"
}

sddm_disable_other_dms() {
    # Deshabilitar GDM si existe
    if systemctl list-unit-files | grep -q "^gdm"; then
        info "Deshabilitando GDM..."
        systemctl disable gdm --now 2>/dev/null || true
    fi
    # Deshabilitar LightDM si existe
    if systemctl list-unit-files | grep -q "^lightdm"; then
        info "Deshabilitando LightDM..."
        systemctl disable lightdm --now 2>/dev/null || true
    fi
}

# ============================================
# GIT CLONE HELPER
# ============================================

pi_clone() {
    local repo="$1"
    local dest="$2"
    local depth="${3:-1}"
    
    if [[ -d "$dest" ]]; then
        rm -rf "$dest"
    fi
    
    git clone --depth="$depth" "$repo" "$dest" || {
        error "No se pudo clonar $repo"
        return 1
    }
}

# ============================================
# BACKUP HELPER
# ============================================

pi_backup() {
    local target="$1"
    if [[ -e "$target" ]]; then
        local backup="${target}.bak.$(date +%Y%m%d%H%M%S)"
        cp -r "$target" "$backup"
        info "Backup creado: $backup"
    fi
}
