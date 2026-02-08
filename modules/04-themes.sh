# ============================================
cat > "$INSTALL_DIR/modules/04-themes.sh" << 'EOF'
#!/bin/bash
# Módulo 04: Instalación de Temas

set -e

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}Módulo 04: Temas y Personalización${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

THEME="${THEME:-none}"
DESKTOP_ENV="${DESKTOP_ENV:-plasma}"

if [[ "$THEME" == "none" ]]; then
    info "No se instalarán temas adicionales"
    exit 0
fi

# Función para instalar tema WhiteSur
install_whitesur() {
    info "Instalando tema WhiteSur..."
    
    cd /tmp
    git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git --depth=1
    cd WhiteSur-gtk-theme
    ./install.sh -a -d "${HOME}/.themes"
    ./install.sh -a -d /usr/share/themes --sudo
    
    # Iconos
    cd /tmp
    git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git --depth=1
    cd WhiteSur-icon-theme
    ./install.sh -d "${HOME}/.icons"
    ./install.sh -d /usr/share/icons --sudo
    
    # Cursor
    ./install.sh -c -d "${HOME}/.icons"
    ./install.sh -c -d /usr/share/icons --sudo
    
    success "Tema WhiteSur instalado"
}

# Función para instalar tema Sweet
install_sweet() {
    info "Instalando tema Sweet..."
    
    # Descargar tema Sweet para KDE
    if [[ "$DESKTOP_ENV" == "plasma" ]]; then
        # Instalar desde AUR si yay/paru está disponible
        if command -v yay &>/dev/null; then
            sudo -u "$SUDO_USER" yay -S --noconfirm \
                sweet-theme-full \
                sweet-cursor-theme \
                candy-icons-git 2>/dev/null || true
        fi
    fi
    
    # GTK Theme
    cd /tmp
    git clone https://github.com/EliverLara/Sweet.git --depth=1
    mkdir -p "${HOME}/.themes"
    cp -r Sweet "${HOME}/.themes/"
    
    success "Tema Sweet instalado"
}

# Función para instalar tema Dracula
install_dracula() {
    info "Instalando tema Dracula..."
    
    # GTK Theme
    cd /tmp
    git clone https://github.com/dracula/gtk.git --depth=1 dracula-gtk
    mkdir -p "${HOME}/.themes"
    cp -r dracula-gtk "${HOME}/.themes/Dracula"
    
    # Iconos
    git clone https://github.com/dracula/gtk-icons.git --depth=1
    mkdir -p "${HOME}/.icons"
    cp -r gtk-icons "${HOME}/.icons/Dracula"
    
    # KDE específico
    if [[ "$DESKTOP_ENV" == "plasma" ]]; then
        # Descargar tema Dracula para Plasma
        curl -L -o /tmp/dracula-plasma.zip "https://github.com/dracula/kde-plasma/archive/refs/heads/main.zip" 2>/dev/null || true
        unzip -o /tmp/dracula-plasma.zip -d /tmp/ 2>/dev/null || true
    fi
    
    success "Tema Dracula instalado"
}

# Función para instalar tema Orchis
install_orchis() {
    info "Instalando tema Orchis..."
    
    cd /tmp
    git clone https://github.com/vinceliuice/Orchis-theme.git --depth=1
    cd Orchis-theme
    ./install.sh -d "${HOME}/.themes"
    ./install.sh -d /usr/share/themes --sudo
    
    # Iconos Tela
    cd /tmp
    git clone https://github.com/vinceliuice/Tela-icon-theme.git --depth=1
    cd Tela-icon-theme
    ./install.sh -d "${HOME}/.icons"
    ./install.sh -d /usr/share/icons --sudo
    
    success "Tema Orchis instalado"
}

# Función para instalar tema Graphite
install_graphite() {
    info "Instalando tema Graphite..."
    
    cd /tmp
    git clone https://github.com/vinceliuice/Graphite-gtk-theme.git --depth=1
    cd Graphite-gtk-theme
    ./install.sh -d "${HOME}/.themes"
    ./install.sh -d /usr/share/themes --sudo
    
    # Iconos
    ./install.sh -i -d "${HOME}/.icons"
    ./install.sh -i -d /usr/share/icons --sudo
    
    success "Tema Graphite instalado"
}

# Instalar tema según selección
case "$THEME" in
    whitesur)
        install_whitesur
        ;;
    sweet)
        install_sweet
        ;;
    dracula)
        install_dracula
        ;;
    orchis)
        install_orchis
        ;;
    graphite)
        install_graphite
        ;;
    *)
        info "Tema no reconocido: $THEME"
        ;;
esac

# Instalar yay si no existe (para AUR)
if ! command -v yay &>/dev/null; then
    info "Instalando yay (AUR helper)..."
    cd /tmp
    git clone https://aur.archlinux.org/yay.git --depth=1
    chown -R "$SUDO_USER:$SUDO_USER" yay
    cd yay
    sudo -u "$SUDO_USER" makepkg -si --noconfirm
fi

success "Módulo Temas completado"
