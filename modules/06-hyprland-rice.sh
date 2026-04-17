#!/bin/bash
# Módulo 06: Hyprland Rice Automático
# Instala HyDE-Project/HyDE (recomendado oficialmente por Hyprland)
# o ML4W como alternativa para principiantes.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/pi-linux-common.sh"

HYPR_RICE="${HYPR_RICE:-hyde}"
DESKTOP_ENV="${DESKTOP_ENV:-hyprland}"

# Si no estamos en Hyprland, omitir
if [[ "$DESKTOP_ENV" != "hyprland" ]]; then
    info "DE no es Hyprland, omitiendo módulo de rice Hyprland"
    exit 0
fi

banner "Módulo 06: Hyprland Rice ($HYPR_RICE)"

# ============================================
# PREPARAR DEPENDENCIAS COMUNES
# ============================================

info "Instalando dependencias previas para rices Hyprland..."

install_pkg \
    base-devel \
    git \
    cmake \
    meson \
    ninja \
    cpio \
    pkgconf \
    rustup \
    go \
    lua \
    lua51 \
    luarocks \
    npm \
    pnpm \
    python \
    python-pip \
    python-pipx \
    python-requests \
    python-pillow \
    python-pywal \
    imagemagick \
    jq \
    bc \
    2>/dev/null || true

# Asegurar yay
ensure_yay

# ============================================
# INSTALAR HYDE-PROJECT/HYDE
# ============================================

install_hyde() {
    info "Instalando HyDE-Project/HyDE..."
    info "Este es el rice más popular y recomendado oficialmente por Hyprland."
    
    local hyde_dir="/tmp/HyDE"
    
    # Backup de configs existentes
    if [[ -d "${PI_CONFIG_DIR}/hypr" ]]; then
        pi_backup "${PI_CONFIG_DIR}/hypr"
    fi
    
    # Clonar
    pi_clone "https://github.com/HyDE-Project/HyDE.git" "$hyde_dir"
    
    # HyDE tiene su propio script de instalación
    cd "$hyde_dir/Scripts"
    
    # El script de HyDE detecta NVIDIA automáticamente y hace backup
    # Se ejecuta como usuario normal (no root) donde sea posible
    if [[ -f "./install.sh" ]]; then
        # El script de HyDE requiere ejecutarse con permisos normales para dotfiles
        # pero necesita sudo para instalar paquetes. Generalmente se ejecuta como user.
        info "Ejecutando instalador de HyDE (puede tardar varios minutos)..."
        
        # Ejecutar como usuario real, pero desde el directorio clonado
        chown -R "${PI_REAL_USER}:${PI_REAL_USER}" "$hyde_dir"
        
        # HyDE's install.sh típicamente pide sudo internamente para pacman
        # pero copia dotfiles como el usuario actual.
        sudo -u "${PI_REAL_USER}" bash "${hyde_dir}/Scripts/install.sh" 2>/dev/null || {
            warning "El instalador de HyDE falló o requiere interacción."
            warning "Puedes instalarlo manualmente después con:"
            warning "  git clone --depth 1 https://github.com/HyDE-Project/HyDE ~/HyDE"
            warning "  cd ~/HyDE/Scripts && ./install.sh"
            return 1
        }
        
        success "HyDE instalado correctamente"
    else
        warning "No se encontró install.sh en HyDE. Instalación manual requerida."
        return 1
    fi
    
    # Limpiar
    rm -rf "$hyde_dir"
}

# ============================================
# INSTALAR ML4W (ALTERNATIVA)
# ============================================

install_ml4w() {
    info "Instalando ML4W Dotfiles (My Linux For Work)..."
    info "Ideal para principiantes. Incluye ISO live y apps GUI de configuración."
    
    # ML4W se instala con un one-liner
    sudo -u "${PI_REAL_USER}" bash <(curl -s https://ml4w.com/os/stable) 2>/dev/null || {
        warning "El instalador de ML4W falló."
        warning "Puedes probar la versión rolling: bash <(curl -s https://ml4w.com/os/rolling)"
        return 1
    }
    
    success "ML4W instalado correctamente"
}

# ============================================
# INSTALAR END-4 (ALTERNATIVA VISUAL)
# ============================================

install_end4() {
    info "Instalando end-4/dots-hyprland (Illogical Impulse)..."
    info "El rice visualmente más impresionante. Requiere Quickshell."
    
    # end-4 usa un one-liner
    sudo -u "${PI_REAL_USER}" bash <(curl -s https://ii.clsty.link/get) 2>/dev/null || {
        warning "El instalador de end-4 falló."
        warning "Alternativa manual: git clone https://github.com/end-4/dots-hyprland && cd dots-hyprland && ./setup install"
        return 1
    }
    
    success "end-4 instalado correctamente"
}

# ============================================
# FALLBACK: DOTFILES MÍNIMOS
# ============================================

install_fallback_dotfiles() {
    warning "Ningún rice automático pudo instalarse."
    info "Configurando dotfiles mínimos de Hyprland..."
    
    mkdir -p "${PI_CONFIG_DIR}/hypr"
    
    cat > "${PI_CONFIG_DIR}/hypr/hyprland.conf" << 'HYPRCONF'
# Configuración mínima de Hyprland (fallback)
monitor=,preferred,auto,auto

input {
    kb_layout = es
    follow_mouse = 1
}

general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
    col.inactive_border = rgba(595959aa)
    layout = dwindle
}

decoration {
    rounding = 10
    blur {
        enabled = true
        size = 3
        passes = 1
    }
    shadow {
        enabled = true
        range = 4
        render_power = 3
        color = rgba(1a1a1aee)
    }
}

animations {
    enabled = yes
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    animation = windows, 1, 7, myBezier
    animation = windowsOut, 1, 7, default, popin 80%
    animation = border, 1, 10, default
    animation = fade, 1, 7, default
    animation = workspaces, 1, 6, default
}

dwindle {
    pseudotile = yes
    preserve_split = yes
}

gestures {
    workspace_swipe = off
}

# Apps esenciales
$terminal = kitty
$fileManager = thunar
$menu = wofi --show drun

# Atajos
bind = SUPER, Return, exec, $terminal
bind = SUPER, Q, killactive,
bind = SUPER, M, exit,
bind = SUPER, E, exec, $fileManager
bind = SUPER, V, togglefloating,
bind = SUPER, R, exec, $menu
bind = SUPER, P, pseudo,
bind = SUPER, J, togglesplit,
bind = SUPER, left, movefocus, l
bind = SUPER, right, movefocus, r
bind = SUPER, up, movefocus, u
bind = SUPER, down, movefocus, d
bind = SUPER, 1, workspace, 1
bind = SUPER, 2, workspace, 2
bind = SUPER, 3, workspace, 3
bind = SUPER, 4, workspace, 4
bind = SUPER, 5, workspace, 5
bind = SUPER SHIFT, 1, movetoworkspace, 1
bind = SUPER SHIFT, 2, movetoworkspace, 2
bind = SUPER SHIFT, 3, movetoworkspace, 3
bind = SUPER SHIFT, 4, movetoworkspace, 4
bind = SUPER SHIFT, 5, movetoworkspace, 5
bind = SUPER, mouse_down, workspace, e+1
bind = SUPER, mouse_up, workspace, e-1
bindm = SUPER, mouse:272, movewindow
bindm = SUPER, mouse:273, resizewindow

# Autostart
exec-once = waybar
exec-once = mako
exec-once = nm-applet --indicator
exec-once = blueman-applet
HYPRCONF
    
    chown -R "${PI_REAL_USER}:${PI_REAL_USER}" "${PI_CONFIG_DIR}/hypr"
    
    # Waybar mínimo
    mkdir -p "${PI_CONFIG_DIR}/waybar"
    cat > "${PI_CONFIG_DIR}/waybar/config" << 'WAYBARCONF'
{
    "layer": "top",
    "modules-left": ["hyprland/workspaces", "hyprland/window"],
    "modules-center": ["clock"],
    "modules-right": ["pulseaudio", "network", "battery", "tray"],
    "clock": { "format": "{:%Y-%m-%d %H:%M}" },
    "battery": { "format": "{capacity}% {icon}", "format-icons": ["", "", "", "", ""] },
    "network": { "format-wifi": "{essid} ({signalStrength}%)", "format-ethernet": "{ipaddr}/{cidr}", "format-disconnected": "Disconnected" },
    "pulseaudio": { "format": "{volume}% {icon}", "format-icons": { "default": ["", ""] } },
    "tray": { "spacing": 10 }
}
WAYBARCONF
    
    chown -R "${PI_REAL_USER}:${PI_REAL_USER}" "${PI_CONFIG_DIR}/waybar"
    
    success "Dotfiles mínimos de Hyprland configurados"
}

# ============================================
# DISPATCH PRINCIPAL
# ============================================

case "$HYPR_RICE" in
    hyde)
        install_hyde || install_fallback_dotfiles
        ;;
    ml4w)
        install_ml4w || install_hyde || install_fallback_dotfiles
        ;;
    end4)
        install_end4 || install_hyde || install_fallback_dotfiles
        ;;
    none)
        info "No se instalará rice automático para Hyprland"
        install_fallback_dotfiles
        ;;
    *)
        warning "Rice Hyprland no reconocido: $HYPR_RICE"
        install_fallback_dotfiles
        ;;
esac

# Asegurar que SDDM puede lanzar Hyprland
if [[ ! -f /usr/share/wayland-sessions/hyprland.desktop ]]; then
    info "Creando entrada de sesión para Hyprland en SDDM..."
    cat > /usr/share/wayland-sessions/hyprland.desktop << 'DESKTOP'
[Desktop Entry]
Name=Hyprland
Comment=An intelligent dynamic tiling Wayland compositor
Exec=Hyprland
Type=Application
DESKTOP
fi

success "Módulo Hyprland Rice completado"
