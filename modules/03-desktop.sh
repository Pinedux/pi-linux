# ============================================
cat > "$INSTALL_DIR/modules/03-desktop.sh" << 'EOF'
#!/bin/bash
# Módulo 03: Instalación del Entorno de Escritorio

set -e

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}Módulo 03: Entorno de Escritorio${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

DESKTOP_ENV="${DESKTOP_ENV:-plasma}"

case "$DESKTOP_ENV" in
    plasma|kde)
        info "Instalando KDE Plasma..."
        
        # Plasma completo
        pacman -S --needed --noconfirm \
            plasma-meta \
            kde-applications-meta \
            sddm \
            sddm-kcm \
            plasma-wayland-session \
            xdg-desktop-portal-kde \
            kdeconnect \
            bluedevil
        
        # Temas y personalización
        pacman -S --needed --noconfirm \
            plasma5-themes-breath 2>/dev/null || true
        
        # Habilitar SDDM
        systemctl enable sddm
        
        success "KDE Plasma instalado"
        ;;
        
    gnome)
        info "Instalando GNOME..."
        
        # GNOME completo
        pacman -S --needed --noconfirm \
            gnome \
            gnome-extra \
            gdm \
            xdg-desktop-portal-gnome \
            gnome-tweaks \
            gnome-shell-extensions \
            extension-manager
        
        # Herramientas adicionales
        pacman -S --needed --noconfirm \
            dconf-editor \
            gnome-themes-extra \
            adwaita-icon-theme
        
        # Habilitar GDM
        systemctl enable gdm
        
        success "GNOME instalado"
        ;;
        
    hyprland)
        info "Instalando Hyprland..."
        
        # Hyprland y dependencias Wayland
        pacman -S --needed --noconfirm \
            hyprland \
            waybar \
            wofi \
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
            qt6-wayland
        
        # Utilidades
        pacman -S --needed --noconfirm \
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
            file-roller
        
        # Fuentes adicionales
        pacman -S --needed --noconfirm \
            otf-font-awesome \
            ttf-jetbrains-mono-nerd \
            ttf-fira-code
        
        success "Hyprland instalado"
        ;;
        
    *)
        error "Entorno de escritorio no soportado: $DESKTOP_ENV"
        exit 1
        ;;
esac

# Instalar componentes comunes
info "Instalando componentes comunes..."
pacman -S --needed --noconfirm \
    xorg-server \
    xorg-xinit \
    xorg-xrandr \
    xorg-xinput \
    xorg-xeyes

success "Módulo Desktop completado"
