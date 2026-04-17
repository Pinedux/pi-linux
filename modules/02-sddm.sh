#!/bin/bash
# Módulo 02: SDDM Unificado
# Instala y configura SDDM como Display Manager único para todos los DEs

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/pi-linux-common.sh"

banner "Módulo 02: SDDM Display Manager"

# ============================================
# 1. INSTALAR SDDM Y DEPENDENCIAS QT6
# ============================================

info "Instalando SDDM y dependencias Qt6..."
install_pkg \
    sddm \
    qt6-svg \
    qt6-virtualkeyboard \
    qt6-multimedia-ffmpeg \
    qt6-declarative \
    qt6-5compat \
    libnewt

success "SDDM instalado"

# ============================================
# 2. INSTALAR TEMA ASTRONAUT
# ============================================

SDDM_THEME_NAME="${SDDM_THEME:-astronaut}"
SDDM_THEME_DIR="/usr/share/sddm/themes/sddm-astronaut-theme"

if [[ "$SDDM_THEME_NAME" == "astronaut" ]] || [[ "$SDDM_THEME_NAME" == "match-de" ]]; then
    if [[ ! -d "$SDDM_THEME_DIR" ]]; then
        info "Instalando tema SDDM Astronaut..."
        pi_clone "https://github.com/Keyitdev/sddm-astronaut-theme.git" "$SDDM_THEME_DIR"
        
        # Instalar fuentes del tema
        if [[ -d "$SDDM_THEME_DIR/Fonts" ]]; then
            cp -r "$SDDM_THEME_DIR/Fonts/"* /usr/share/fonts/ 2>/dev/null || true
            fc-cache -fv 2>/dev/null || true
        fi
        
        success "Tema Astronaut instalado"
    else
        info "Tema Astronaut ya existe, omitiendo..."
    fi
    SDDM_THEME_NAME="sddm-astronaut-theme"
fi

# ============================================
# 3. CONFIGURAR SDDM
# ============================================

info "Configurando SDDM..."

mkdir -p /etc/sddm.conf.d

# Tema
cat > /etc/sddm.conf.d/theme.conf <<EOF
[Theme]
Current=${SDDM_THEME_NAME}
EOF

# Teclado virtual (opcional pero recomendado para tablets/touch)
cat > /etc/sddm.conf.d/virtualkbd.conf <<EOF
[General]
InputMethod=qtvirtualkeyboard
EOF

# Configuración general
cat > /etc/sddm.conf.d/general.conf <<EOF
[General]
DisplayServer=x11
GreeterEnvironment=QT_WAYLAND_SHELL_INTEGRATION=layer-shell,QT_AUTO_SCREEN_SCALE_FACTOR=1

[X11]
ServerArguments=-nolisten tcp
EOF

# Layout de teclado en SDDM
localectl set-x11-keymap es 2>/dev/null || warning "No se pudo configurar keymap es en SDDM"

success "SDDM configurado"

# ============================================
# 4. DESHABILITAR OTROS DISPLAY MANAGERS
# ============================================

sddm_disable_other_dms

# ============================================
# 5. HABILITAR SDDM
# ============================================

sddm_enable

# ============================================
# 6. AVATARES DE USUARIO
# ============================================

if [[ -n "$PI_REAL_USER" ]]; then
    USER_FACE="${PI_USER_HOME}/.face.icon"
    if [[ ! -f "$USER_FACE" ]]; then
        info "Configurando avatar de usuario para SDDM..."
        # Crear un avatar genérico si no existe
        touch "$USER_FACE" 2>/dev/null || true
        chown "${PI_REAL_USER}:${PI_REAL_USER}" "$USER_FACE" 2>/dev/null || true
        setfacl -m u:sddm:x "${PI_USER_HOME}" 2>/dev/null || true
        setfacl -m u:sddm:r "$USER_FACE" 2>/dev/null || true
    fi
fi

success "Módulo SDDM completado"
