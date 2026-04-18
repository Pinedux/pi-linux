#!/bin/bash
# Módulo 03: Instalación del Entorno de Escritorio
# SDDM ya está instalado en el módulo 02. Este módulo instala solo el DE.

set -e
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/pi-linux-common.sh"

DESKTOP_ENV="${DESKTOP_ENV:-plasma}"

banner "Módulo 03: Entorno de Escritorio ($DESKTOP_ENV)"

case "$DESKTOP_ENV" in
    plasma|kde)
        info "Instalando KDE Plasma 6..."
        
        install_pkg \
            plasma-meta \
            kde-applications-meta \
            xdg-desktop-portal-kde \
            kdeconnect \
            bluedevil \
            kvantum \
            kvantum-qt5 \
            sddm-kcm
        
        success "KDE Plasma instalado"
        ;;
        
    gnome)
        info "Instalando GNOME..."
        
        install_pkg \
            gnome \
            gnome-extra \
            gnome-tweaks \
            gnome-shell-extensions \
            gnome-browser-connector \
            dconf-editor \
            gnome-themes-extra \
            adwaita-icon-theme \
            xdg-desktop-portal-gnome
        
        # No instalamos GDM. SDDM (del módulo 02) gestionará el login.
        
        # GNOME metapackage instala GDM; lo deshabilitamos para evitar conflicto con SDDM
        if systemctl list-unit-files | grep -q "^gdm"; then
            info "Deshabilitando GDM para evitar conflicto con SDDM..."
            systemctl disable gdm --now 2>/dev/null || true
        fi
        
        install_aur extension-manager
        
        success "GNOME instalado"
        ;;
        
    hyprland)
        info "Instalando Hyprland..."
        
        install_pkg \
            hyprland \
            waybar \
            wofi \
            rofi-wayland \
            foot \
            mako \
            libnotify \
            grim \
            slurp \
            wl-clipboard \
            cliphist \
            swww \
            swaylock-effects \
            swayidle \
            wlogout \
            polkit-kde-agent \
            xdg-desktop-portal-hyprland \
            xdg-desktop-portal-gtk \
            qt5-wayland \
            qt6-wayland \
            brightnessctl \
            pamixer \
            pavucontrol \
            network-manager-applet \
            blueman \
            thunar \
            thunar-archive-plugin \
            gvfs \
            gvfs-mtp \
            gvfs-afc \
            gvfs-smb \
            file-roller \
            otf-font-awesome \
            ttf-jetbrains-mono-nerd \
            ttf-fira-code \
            ttf-hack-nerd \
            ttf-meslo-nerd \
            ttf-ubuntu-nerd
        
        # Hyprland no tiene DM propio. SDDM del módulo 02 ya está habilitado.
        success "Hyprland instalado"
        ;;
        
    *)
        error "Entorno de escritorio no soportado: $DESKTOP_ENV"
        exit 1
        ;;
esac

# ============================================
# COMPONENTES COMUNES X11/WAYLAND
# ============================================

info "Instalando componentes gráficos comunes..."

install_pkg \
    xorg-server \
    xorg-xinit \
    xorg-xrandr \
    xorg-xinput \
    xorg-xeyes \
    mesa-demos \
    glxinfo \
    vulkan-tools \
    libva-utils \
    2>/dev/null || true

success "Módulo Desktop completado"
