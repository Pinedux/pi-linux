# ============================================
cat > "$INSTALL_DIR/modules/06-dotfiles.sh" << 'EOF'
#!/bin/bash
# Módulo 06: Configuración de Dotfiles de Hyprland
# Copia la configuración actual de Hyprland del usuario

set -e

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}Módulo 06: Dotfiles de Hyprland${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

info "Configurando dotfiles de Hyprland..."

# Directorio de configuración destino
USER_HOME="$(eval echo ~${SUDO_USER})"
CONFIG_DIR="${USER_HOME}/.config"

# Crear directorio .config si no existe
mkdir -p "${CONFIG_DIR}"

# Lista de configuraciones de Hyprland a copiar
HYPR_CONFIGS=(
    "hypr"
    "hyprlock"
    "waybar"
    "wofi"
    "mako"
    "foot"
    "kitty"
)

# Copiar configuraciones
copy_config() {
    local src="/home/pinedux/.config/$1"
    local dst="${CONFIG_DIR}/$1"
    
    if [[ -d "$src" ]]; then
        info "Copiando configuración: $1"
        cp -r "$src" "$dst"
        chown -R "${SUDO_USER}:${SUDO_USER}" "$dst"
        success "$1 configurado"
    else
        warning "Configuración no encontrada: $1"
    fi
}

# Copiar cada configuración
for config in "${HYPR_CONFIGS[@]}"; do
    copy_config "$config"
done

# Copiar scripts personalizados si existen
if [[ -d "/home/pinedux/.config/hypr/scripts" ]]; then
    mkdir -p "${CONFIG_DIR}/hypr/scripts"
    cp -r /home/pinedux/.config/hypr/scripts/* "${CONFIG_DIR}/hypr/scripts/" 2>/dev/null || true
    chmod +x "${CONFIG_DIR}/hypr/scripts/"* 2>/dev/null || true
    chown -R "${SUDO_USER}:${SUDO_USER}" "${CONFIG_DIR}/hypr/scripts"
fi

# Configurar wallpaper
if [[ -d "/home/pinedux/Pictures/wallpapers" ]]; then
    mkdir -p "${USER_HOME}/Pictures/wallpapers"
    cp -r /home/pinedux/Pictures/wallpapers/* "${USER_HOME}/Pictures/wallpapers/" 2>/dev/null || true
    chown -R "${SUDO_USER}:${SUDO_USER}" "${USER_HOME}/Pictures/wallpapers"
fi

# Configurar tema de cursor
cat > "${CONFIG_DIR}/gtk-3.0/settings.ini" << 'GTKCONF'
[Settings]
gtk-theme-name=Arc-Dark
gtk-icon-theme-name=Papirus
gtk-font-name=Noto Sans 11
gtk-cursor-theme-name=Bibata-Modern-Ice
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=0
gtk-menu-images=0
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=0
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintslight
gtk-xft-rgba=rgb
gtk-application-prefer-dark-theme=1
GTKCONF

chown "${SUDO_USER}:${SUDO_USER}" "${CONFIG_DIR}/gtk-3.0/settings.ini"

# Instalar más fuentes Nerd
info "Instalando fuentes adicionales..."
pacman -S --needed --noconfirm \
    ttf-jetbrains-mono-nerd \
    ttf-fira-code-nerd \
    ttf-hack-nerd \
    ttf-meslo-nerd \
    ttf-ubuntu-nerd \
    otf-font-awesome

# Configurar aplicaciones por defecto
mkdir -p "${CONFIG_DIR}/mimeapps.list"

# Crear script de inicio para Hyprland
cat > "${USER_HOME}/.hyprland-init.sh" << 'INIT'
#!/bin/bash
# Script de inicio para Hyprland

# Iniciar servicios necesarios
systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP

dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP

# Iniciar waybar
waybar &

# Iniciar notificaciones
mako &

# Iniciar cliphist
wl-paste --type text --watch cliphist store &
wl-paste --type image --watch cliphist store &

# Fondo de pantalla
swww init &
swww img ~/Pictures/wallpapers/default.jpg &

# Applets
nm-applet --indicator &
blueman-applet &
INIT

chmod +x "${USER_HOME}/.hyprland-init.sh"
chown "${SUDO_USER}:${SUDO_USER}" "${USER_HOME}/.hyprland-init.sh"

success "Dotfiles de Hyprland configurados"
info "Puedes iniciar Hyprland con: Hyprland"
