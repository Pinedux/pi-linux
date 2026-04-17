#!/bin/bash
# Script complementario - Módulos 02-06 de Pi-Linux
# Ejecutar después de pi-linux-installer-complete.sh

INSTALL_DIR="${HOME}/www/pi_linux"

# Crear módulos si no existen
mkdir -p "$INSTALL_DIR/modules"

# ============================================
# MÓDULO 02: GPU
# ============================================
cat > "$INSTALL_DIR/modules/02-gpu.sh" << 'EOF'
#!/bin/bash
# Módulo 02: Instalación de drivers GPU

set -e

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}Módulo 02: Drivers GPU${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Detectar GPU si es auto
if [[ "$GPU_TYPE" == "auto" ]] || [[ -z "$GPU_TYPE" ]]; then
    info "Detectando GPU..."
    if lspci | grep -i nvidia &>/dev/null; then
        GPU_TYPE="nvidia"
    elif lspci | grep -i amd &>/dev/null; then
        GPU_TYPE="amd"
    elif lspci | grep -i intel &>/dev/null; then
        GPU_TYPE="intel"
    else
        GPU_TYPE="generic"
    fi
    info "GPU detectada: $GPU_TYPE"
fi

case "$GPU_TYPE" in
    nvidia|nvidia-open)
        info "Instalando drivers NVIDIA..."
        
        # Instalar drivers NVIDIA
        pacman -S --needed --noconfirm \
            nvidia-dkms \
            nvidia-utils \
            nvidia-settings \
            lib32-nvidia-utils \
            opencl-nvidia \
            libvdpau-va-gl
        
        # Configuración de NVIDIA
        cat > /etc/modprobe.d/nvidia.conf << 'NVCONF'
options nvidia-drm modeset=1
options nvidia NVreg_UsePageAttributeTable=1
options nvidia NVreg_RegistryDwords="PowerMizerEnable=0x1; PerfLevelSrc=0x2222; PowerMizerDefaultAC=0x1"
NVCONF
        
        # Hook de mkinitcpio para NVIDIA
        mkdir -p /etc/pacman.d/hooks
        cat > /etc/pacman.d/hooks/nvidia.hook << 'HOOK'
[Trigger]
Operation=Install
Operation=Upgrade
Operation=Remove
Type=Package
Target=nvidia-dkms
Target=linux

[Action]
Description=Update NVIDIA module in initcpio
Depends=mkinitcpio
When=PostTransaction
NeedsTargets
Exec=/bin/sh -c 'while read -r trg; do case $trg in linux*) exit 0; esac; done; /usr/bin/mkinitcpio -P'
HOOK
        
        # Regenerar initramfs
        mkinitcpio -P
        
        success "Drivers NVIDIA instalados"
        ;;
        
    amd)
        info "Instalando drivers AMD/ATI..."
        
        pacman -S --needed --noconfirm \
            mesa \
            lib32-mesa \
            xf86-video-amdgpu \
            xf86-video-ati \
            vulkan-radeon \
            lib32-vulkan-radeon \
            vulkan-icd-loader \
            lib32-vulkan-icd-loader \
            libva-mesa-driver \
            lib32-libva-mesa-driver \
            mesa-vdpau \
            lib32-mesa-vdpau \
            opencl-amd 2>/dev/null || true
        
        success "Drivers AMD instalados"
        ;;
        
    intel)
        info "Instalando drivers Intel..."
        
        pacman -S --needed --noconfirm \
            mesa \
            lib32-mesa \
            xf86-video-intel \
            vulkan-intel \
            lib32-vulkan-intel \
            vulkan-icd-loader \
            lib32-vulkan-icd-loader \
            intel-media-driver \
            libva-intel-driver \
            libva-utils
        
        success "Drivers Intel instalados"
        ;;
        
    vm)
        info "Instalando drivers para máquina virtual..."
        
        if lspci | grep -i virtualbox &>/dev/null; then
            pacman -S --needed --noconfirm \
                virtualbox-guest-utils
            systemctl enable vboxservice
        elif lspci | grep -i vmware &>/dev/null; then
            pacman -S --needed --noconfirm \
                open-vm-tools
            systemctl enable vmtoolsd
        elif lspci | grep -i qemu &>/dev/null; then
            pacman -S --needed --noconfirm \
                qemu-guest-agent
            systemctl enable qemu-guest-agent
        fi
        
        success "Drivers VM instalados"
        ;;
        
    generic|*)
        info "Instalando drivers genéricos..."
        
        pacman -S --needed --noconfirm \
            mesa \
            lib32-mesa \
            xf86-video-vesa \
            xf86-video-fbdev
        
        success "Drivers genéricos instalados"
        ;;
esac

# Instalar utilidades comunes
info "Instalando utilidades de GPU..."
pacman -S --needed --noconfirm \
    mesa-demos \
    glxinfo \
    vulkan-tools \
    libva-utils

success "Módulo GPU completado"
EOF

# ============================================
# MÓDULO 03: Desktop Environment
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
EOF

# ============================================
# MÓDULO 04: Temas
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
EOF

# ============================================
# MÓDULO 05: Software Adicional
# ============================================
cat > "$INSTALL_DIR/modules/05-software.sh" << 'EOF'
#!/bin/bash
# Módulo 05: Instalación de Software Adicional

set -e

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}Módulo 05: Software Adicional${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ============================================
# NAVEGADORES
# ============================================

if [[ "${INSTALL_CHROME:-n}" == "y" ]] || [[ "${INSTALL_CHROME:-n}" == "Y" ]] || [[ "${INSTALL_CHROME:-n}" == "s" ]] || [[ "${INSTALL_CHROME:-n}" == "S" ]]; then
    info "Instalando Google Chrome..."
    cd /tmp
    wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm -O chrome.rpm 2>/dev/null || \
    curl -O https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.pkg.tar.zst 2>/dev/null || \
    sudo -u "$SUDO_USER" yay -S --noconfirm google-chrome 2>/dev/null || true
    success "Google Chrome instalado"
fi

if [[ "${INSTALL_BRAVE:-n}" == "y" ]] || [[ "${INSTALL_BRAVE:-n}" == "Y" ]] || [[ "${INSTALL_BRAVE:-n}" == "s" ]] || [[ "${INSTALL_BRAVE:-n}" == "S" ]]; then
    info "Instalando Brave..."
    pacman -S --needed --noconfirm brave-browser 2>/dev/null || \
    sudo -u "$SUDO_USER" yay -S --noconfirm brave-bin 2>/dev/null || true
    success "Brave instalado"
fi

if [[ "${INSTALL_FIREFOX:-n}" == "y" ]] || [[ "${INSTALL_FIREFOX:-n}" == "Y" ]] || [[ "${INSTALL_FIREFOX:-n}" == "s" ]] || [[ "${INSTALL_FIREFOX:-n}" == "S" ]]; then
    info "Instalando Firefox..."
    pacman -S --needed --noconfirm firefox firefox-i18n-es-es
    success "Firefox instalado"
fi

# ============================================
# PRODUCTIVIDAD
# ============================================

if [[ "${INSTALL_VSCODE:-n}" == "y" ]] || [[ "${INSTALL_VSCODE:-n}" == "Y" ]] || [[ "${INSTALL_VSCODE:-n}" == "s" ]] || [[ "${INSTALL_VSCODE:-n}" == "S" ]]; then
    info "Instalando Visual Studio Code..."
    pacman -S --needed --noconfirm code 2>/dev/null || \
    sudo -u "$SUDO_USER" yay -S --noconfirm visual-studio-code-bin
    success "VS Code instalado"
fi

if [[ "${INSTALL_OBSIDIAN:-n}" == "y" ]] || [[ "${INSTALL_OBSIDIAN:-n}" == "Y" ]] || [[ "${INSTALL_OBSIDIAN:-n}" == "s" ]] || [[ "${INSTALL_OBSIDIAN:-n}" == "S" ]]; then
    info "Instalando Obsidian..."
    sudo -u "$SUDO_USER" yay -S --noconfirm obsidian
    success "Obsidian instalado"
fi

# ============================================
# MULTIMEDIA
# ============================================

if [[ "${INSTALL_VLC:-n}" == "y" ]] || [[ "${INSTALL_VLC:-n}" == "Y" ]] || [[ "${INSTALL_VLC:-n}" == "s" ]] || [[ "${INSTALL_VLC:-n}" == "S" ]]; then
    info "Instalando VLC..."
    pacman -S --needed --noconfirm vlc
    success "VLC instalado"
fi

if [[ "${INSTALL_SPOTIFY:-n}" == "y" ]] || [[ "${INSTALL_SPOTIFY:-n}" == "Y" ]] || [[ "${INSTALL_SPOTIFY:-n}" == "s" ]] || [[ "${INSTALL_SPOTIFY:-n}" == "S" ]]; then
    info "Instalando Spotify..."
    sudo -u "$SUDO_USER" yay -S --noconfirm spotify
    success "Spotify instalado"
fi

if [[ "${INSTALL_OBS:-n}" == "y" ]] || [[ "${INSTALL_OBS:-n}" == "Y" ]] || [[ "${INSTALL_OBS:-n}" == "s" ]] || [[ "${INSTALL_OBS:-n}" == "S" ]]; then
    info "Instalando OBS Studio..."
    pacman -S --needed --noconfirm obs-studio
    success "OBS instalado"
fi

# ============================================
# TERMINALES
# ============================================

if [[ "${INSTALL_KITTY:-n}" == "y" ]] || [[ "${INSTALL_KITTY:-n}" == "Y" ]] || [[ "${INSTALL_KITTY:-n}" == "s" ]] || [[ "${INSTALL_KITTY:-n}" == "S" ]]; then
    info "Instalando kitty..."
    pacman -S --needed --noconfirm kitty kitty-terminfo
    success "kitty instalado"
fi

if [[ "${INSTALL_ALACRITTY:-n}" == "y" ]] || [[ "${INSTALL_ALACRITTY:-n}" == "Y" ]] || [[ "${INSTALL_ALACRITTY:-n}" == "s" ]] || [[ "${INSTALL_ALACRITTY:-n}" == "S" ]]; then
    info "Instalando alacritty..."
    pacman -S --needed --noconfirm alacritty
    success "alacritty instalado"
fi

# ============================================
# DESARROLLO
# ============================================

if [[ "${INSTALL_DOCKER:-n}" == "y" ]] || [[ "${INSTALL_DOCKER:-n}" == "Y" ]] || [[ "${INSTALL_DOCKER:-n}" == "s" ]] || [[ "${INSTALL_DOCKER:-n}" == "S" ]]; then
    info "Instalando Docker..."
    pacman -S --needed --noconfirm docker docker-compose
    systemctl enable docker
    usermod -aG docker "$SUDO_USER" 2>/dev/null || true
    success "Docker instalado"
fi

if [[ "${INSTALL_NODEJS:-n}" == "y" ]] || [[ "${INSTALL_NODEJS:-n}" == "Y" ]] || [[ "${INSTALL_NODEJS:-n}" == "s" ]] || [[ "${INSTALL_NODEJS:-n}" == "S" ]]; then
    info "Instalando Node.js..."
    pacman -S --needed --noconfirm nodejs npm
    # Instalar nvm
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
    success "Node.js instalado"
fi

if [[ "${INSTALL_PYTHON:-n}" == "y" ]] || [[ "${INSTALL_PYTHON:-n}" == "Y" ]] || [[ "${INSTALL_PYTHON:-n}" == "s" ]] || [[ "${INSTALL_PYTHON:-n}" == "S" ]]; then
    info "Instalando Python completo..."
    pacman -S --needed --noconfirm \
        python \
        python-pip \
        python-virtualenv \
        python-pipx \
        ipython \
        python-poetry \
        python-pyenv
    success "Python instalado"
fi

# ============================================
# HERRAMIENTAS CLI MODERNAS
# ============================================

info "Instalando herramientas CLI..."

if [[ "${INSTALL_FZF:-n}" == "y" ]] || [[ "${INSTALL_FZF:-n}" == "Y" ]] || [[ "${INSTALL_FZF:-n}" == "s" ]] || [[ "${INSTALL_FZF:-n}" == "S" ]]; then
    pacman -S --needed --noconfirm fzf
    # Configurar fzf
    echo 'eval "$(fzf --bash)"' >> "${HOME}/.bashrc"
fi

if [[ "${INSTALL_RIPGREP:-n}" == "y" ]] || [[ "${INSTALL_RIPGREP:-n}" == "Y" ]] || [[ "${INSTALL_RIPGREP:-n}" == "s" ]] || [[ "${INSTALL_RIPGREP:-n}" == "S" ]]; then
    pacman -S --needed --noconfirm ripgrep
fi

if [[ "${INSTALL_FD:-n}" == "y" ]] || [[ "${INSTALL_FD:-n}" == "Y" ]] || [[ "${INSTALL_FD:-n}" == "s" ]] || [[ "${INSTALL_FD:-n}" == "S" ]]; then
    pacman -S --needed --noconfirm fd
fi

if [[ "${INSTALL_BAT:-n}" == "y" ]] || [[ "${INSTALL_BAT:-n}" == "Y" ]] || [[ "${INSTALL_BAT:-n}" == "s" ]] || [[ "${INSTALL_BAT:-n}" == "S" ]]; then
    pacman -S --needed --noconfirm bat
    # Crear alias cat -> bat
    echo 'alias cat="bat --style=plain"' >> "${HOME}/.bashrc"
fi

if [[ "${INSTALL_EZA:-n}" == "y" ]] || [[ "${INSTALL_EZA:-n}" == "Y" ]] || [[ "${INSTALL_EZA:-n}" == "s" ]] || [[ "${INSTALL_EZA:-n}" == "S" ]]; then
    pacman -S --needed --noconfirm eza
    # Crear alias ls -> eza
    echo 'alias ls="eza --icons"' >> "${HOME}/.bashrc"
    echo 'alias ll="eza -la --icons"' >> "${HOME}/.bashrc"
    echo 'alias la="eza -a --icons"' >> "${HOME}/.bashrc"
    echo 'alias tree="eza --tree --icons"' >> "${HOME}/.bashrc"
fi

if [[ "${INSTALL_ZOXIDE:-n}" == "y" ]] || [[ "${INSTALL_ZOXIDE:-n}" == "Y" ]] || [[ "${INSTALL_ZOXIDE:-n}" == "s" ]] || [[ "${INSTALL_ZOXIDE:-n}" == "S" ]]; then
    pacman -S --needed --noconfirm zoxide
    # Configurar zoxide
    echo 'eval "$(zoxide init bash)"' >> "${HOME}/.bashrc"
    echo 'alias cd="z"' >> "${HOME}/.bashrc"
fi

if [[ "${INSTALL_ATUIN:-n}" == "y" ]] || [[ "${INSTALL_ATUIN:-n}" == "Y" ]] || [[ "${INSTALL_ATUIN:-n}" == "s" ]] || [[ "${INSTALL_ATUIN:-n}" == "S" ]]; then
    sudo -u "$SUDO_USER" bash -c "curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh"
fi

if [[ "${INSTALL_DELTA:-n}" == "y" ]] || [[ "${INSTALL_DELTA:-n}" == "Y" ]] || [[ "${INSTALL_DELTA:-n}" == "s" ]] || [[ "${INSTALL_DELTA:-n}" == "S" ]]; then
    pacman -S --needed --noconfirm git-delta
fi

success "Herramientas CLI instaladas"

# ============================================
# EDITORES
# ============================================

if [[ "${INSTALL_NEOVIM:-n}" == "y" ]] || [[ "${INSTALL_NEOVIM:-n}" == "Y" ]] || [[ "${INSTALL_NEOVIM:-n}" == "s" ]] || [[ "${INSTALL_NEOVIM:-n}" == "S" ]]; then
    info "Instalando Neovim..."
    pacman -S --needed --noconfirm neovim
    
    # Dependencias comunes
    pacman -S --needed --noconfirm \
        nodejs \
        npm \
        python-pynvim \
        luarocks \
        tree-sitter-cli
    
    success "Neovim instalado"
fi

if [[ "${INSTALL_LAZYVIM:-n}" == "y" ]] || [[ "${INSTALL_LAZYVIM:-n}" == "Y" ]] || [[ "${INSTALL_LAZYVIM:-n}" == "s" ]] || [[ "${INSTALL_LAZYVIM:-n}" == "S" ]]; then
    info "Instalando LazyVim..."
    # Backup de configuración existente
    mv "${HOME}/.config/nvim" "${HOME}/.config/nvim.bak.$(date +%Y%m%d)" 2>/dev/null || true
    mv "${HOME}/.local/share/nvim" "${HOME}/.local/share/nvim.bak.$(date +%Y%m%d)" 2>/dev/null || true
    mv "${HOME}/.local/state/nvim" "${HOME}/.local/state/nvim.bak.$(date +%Y%m%d)" 2>/dev/null || true
    mv "${HOME}/.cache/nvim" "${HOME}/.cache/nvim.bak.$(date +%Y%m%d)" 2>/dev/null || true
    
    # Clonar LazyVim starter
    git clone https://github.com/LazyVim/starter "${HOME}/.config/nvim"
    rm -rf "${HOME}/.config/nvim/.git"
    
    success "LazyVim instalado"
fi

if [[ "${INSTALL_DOOMEMACS:-n}" == "y" ]] || [[ "${INSTALL_DOOMEMACS:-n}" == "Y" ]] || [[ "${INSTALL_DOOMEMACS:-n}" == "s" ]] || [[ "${INSTALL_DOOMEMACS:-n}" == "S" ]]; then
    info "Instalando Doom Emacs..."
    pacman -S --needed --noconfirm emacs
    git clone --depth 1 https://github.com/doomemacs/doomemacs "${HOME}/.config/emacs"
    "${HOME}/.config/emacs/bin/doom" install
    success "Doom Emacs instalado"
fi

# ============================================
# MONITORES
# ============================================

if [[ "${INSTALL_BTOP:-n}" == "y" ]] || [[ "${INSTALL_BTOP:-n}" == "Y" ]] || [[ "${INSTALL_BTOP:-n}" == "s" ]] || [[ "${INSTALL_BTOP:-n}" == "S" ]]; then
    info "Instalando btop..."
    pacman -S --needed --noconfirm btop
    mkdir -p "${HOME}/.config/btop"
    success "btop instalado"
fi

if [[ "${INSTALL_NVTOP:-n}" == "y" ]] || [[ "${INSTALL_NVTOP:-n}" == "Y" ]] || [[ "${INSTALL_NVTOP:-n}" == "s" ]] || [[ "${INSTALL_NVTOP:-n}" == "S" ]]; then
    info "Instalando nvtop..."
    pacman -S --needed --noconfirm nvtop
    success "nvtop instalado"
fi

# ============================================
# SHELLS
# ============================================

if [[ "${INSTALL_ZSH:-n}" == "y" ]] || [[ "${INSTALL_ZSH:-n}" == "Y" ]] || [[ "${INSTALL_ZSH:-n}" == "s" ]] || [[ "${INSTALL_ZSH:-n}" == "S" ]]; then
    info "Instalando Zsh..."
    pacman -S --needed --noconfirm zsh zsh-completions zsh-syntax-highlighting zsh-autosuggestions
    
    # Cambiar shell por defecto
    chsh -s /bin/zsh "$SUDO_USER" 2>/dev/null || true
    success "Zsh instalado"
fi

if [[ "${INSTALL_OHMYZSH:-n}" == "y" ]] || [[ "${INSTALL_OHMYZSH:-n}" == "Y" ]] || [[ "${INSTALL_OHMYZSH:-n}" == "s" ]] || [[ "${INSTALL_OHMYZSH:-n}" == "S" ]]; then
    info "Instalando Oh-My-Zsh..."
    sudo -u "$SUDO_USER" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    
    # Instalar plugins adicionales
    git clone https://github.com/zsh-users/zsh-autosuggestions "${HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions" 2>/dev/null || true
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "${HOME}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" 2>/dev/null || true
    git clone https://github.com/zdharma-continuum/fast-syntax-highlighting "${HOME}/.oh-my-zsh/custom/plugins/fast-syntax-highlighting" 2>/dev/null || true
    
    success "Oh-My-Zsh instalado"
fi

if [[ "${INSTALL_FISH:-n}" == "y" ]] || [[ "${INSTALL_FISH:-n}" == "Y" ]] || [[ "${INSTALL_FISH:-n}" == "s" ]] || [[ "${INSTALL_FISH:-n}" == "S" ]]; then
    info "Instalando Fish..."
    pacman -S --needed --noconfirm fish
fi

if [[ "${INSTALL_STARSHIP:-n}" == "y" ]] || [[ "${INSTALL_STARSHIP:-n}" == "Y" ]] || [[ "${INSTALL_STARSHIP:-n}" == "s" ]] || [[ "${INSTALL_STARSHIP:-n}" == "S" ]]; then
    info "Instalando Starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y
    echo 'eval "$(starship init bash)"' >> "${HOME}/.bashrc"
    mkdir -p "${HOME}/.config" && starship preset pure-preset -o "${HOME}/.config/starship.toml"
    success "Starship instalado"
fi

# ============================================
# TMUX
# ============================================

if [[ "${INSTALL_TMUX:-n}" == "y" ]] || [[ "${INSTALL_TMUX:-n}" == "Y" ]] || [[ "${INSTALL_TMUX:-n}" == "s" ]] || [[ "${INSTALL_TMUX:-n}" == "S" ]]; then
    info "Instalando tmux..."
    pacman -S --needed --noconfirm tmux
    success "tmux instalado"
fi

if [[ "${INSTALL_OHMYTMUX:-n}" == "y" ]] || [[ "${INSTALL_OHMYTMUX:-n}" == "Y" ]] || [[ "${INSTALL_OHMYTMUX:-n}" == "s" ]] || [[ "${INSTALL_OHMYTMUX:-n}" == "S" ]]; then
    info "Instalando Oh-My-Tmux..."
    cd "${HOME}"
    git clone https://github.com/gpakosz/.tmux.git
    ln -s -f .tmux/.tmux.conf
    cp .tmux/.tmux.conf.local .
    success "Oh-My-Tmux instalado"
fi

success "Módulo Software completado"
EOF

# ============================================
# MÓDULO 06: Dotfiles Hyprland
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
EOF

# ============================================
# CONFIGURACIÓN DESATENDIDA
# ============================================
cat > "$INSTALL_DIR/config/unattended.conf" << 'EOF'
#!/bin/bash
# Pi-Linux - Configuración de Instalación Desatendida
# Este archivo define los valores por defecto para modo automático

# ============================================
# CONFIGURACIÓN DEL SISTEMA
# ============================================

# Entorno de escritorio: plasma, gnome, hyprland
DESKTOP_ENV="plasma"

# Tema a instalar (plasma/gnome): whitesur, sweet, dracula, orchis, graphite, none
THEME="whitesur"

# Tipo de GPU: auto, nvidia, nvidia-open, amd, intel, vm, generic
GPU_TYPE="auto"

# Nombre del usuario
USERNAME="pi"

# Nombre del equipo
HOSTNAME="pi-linux"

# Zona horaria
TIMEZONE="Europe/Madrid"

# Locale
LOCALE="es_ES.UTF-8"

# Keymap
KEYMAP="es"

# ============================================
# SOFTWARE A INSTALAR (y = sí, n = no)
# ============================================

# Navegadores
INSTALL_CHROME="y"
INSTALL_BRAVE="n"
INSTALL_FIREFOX="y"

# Productividad
INSTALL_VSCODE="y"
INSTALL_OBSIDIAN="n"

# Multimedia
INSTALL_VLC="y"
INSTALL_SPOTIFY="y"
INSTALL_OBS="n"

# Terminales
INSTALL_KITTY="y"
INSTALL_ALACRITTY="n"

# Desarrollo
INSTALL_DOCKER="y"
INSTALL_NODEJS="y"
INSTALL_PYTHON="y"

# Herramientas CLI
INSTALL_FZF="y"
INSTALL_RIPGREP="y"
INSTALL_FD="y"
INSTALL_BAT="y"
INSTALL_EZA="y"
INSTALL_ZOXIDE="y"
INSTALL_ATUIN="n"
INSTALL_DELTA="n"

# Editores
INSTALL_NEOVIM="y"
INSTALL_LAZYVIM="n"
INSTALL_DOOMEMACS="n"

# Monitores
INSTALL_BTOP="y"
INSTALL_NVTOP="y"

# Shells
INSTALL_ZSH="y"
INSTALL_OHMYZSH="y"
INSTALL_FISH="n"
INSTALL_STARSHIP="y"

# Tmux
INSTALL_TMUX="y"
INSTALL_OHMYTMUX="n"
EOF

echo "========================================"
echo "  ✅ Módulos 02-06 creados"
echo "========================================"
echo ""
echo "Ubicación: $INSTALL_DIR/modules/"
echo ""
