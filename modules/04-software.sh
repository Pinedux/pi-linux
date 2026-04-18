#!/bin/bash
# Módulo 04: Software Esencial
# Instala navegadores, editores, herramientas CLI y utilidades básicas

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/pi-linux-common.sh"

banner "Módulo 04: Software Esencial"

# ============================================
# NAVEGADORES
# ============================================

if is_yes "${INSTALL_FIREFOX}"; then
    info "Instalando Firefox..."
    install_pkg firefox firefox-i18n-es-es
    tracker_mark_installed "INSTALL_FIREFOX" "y"
    success "Firefox instalado"
fi

if is_yes "${INSTALL_CHROME}"; then
    info "Instalando Google Chrome..."
    cd /tmp
    wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm -O chrome.rpm 2>/dev/null || \
    curl -O https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.pkg.tar.zst 2>/dev/null || \
    install_aur google-chrome 2>/dev/null || true
    tracker_mark_installed "INSTALL_CHROME" "y"
    success "Google Chrome instalado"
fi

if is_yes "${INSTALL_BRAVE}"; then
    info "Instalando Brave..."
    install_pkg brave-browser 2>/dev/null || install_aur brave-bin 2>/dev/null || true
    tracker_mark_installed "INSTALL_BRAVE" "y"
    success "Brave instalado"
fi

# ============================================
# PRODUCTIVIDAD
# ============================================

if is_yes "${INSTALL_VSCODE}"; then
    info "Instalando Visual Studio Code..."
    install_pkg code 2>/dev/null || install_aur visual-studio-code-bin
    tracker_mark_installed "INSTALL_VSCODE" "y"
    success "VS Code instalado"
fi

if is_yes "${INSTALL_OBSIDIAN}"; then
    info "Instalando Obsidian..."
    install_aur obsidian
    tracker_mark_installed "INSTALL_OBSIDIAN" "y"
    success "Obsidian instalado"
fi

# ============================================
# MULTIMEDIA
# ============================================

if is_yes "${INSTALL_VLC}"; then
    info "Instalando VLC..."
    install_pkg vlc
    tracker_mark_installed "INSTALL_VLC" "y"
    success "VLC instalado"
fi

if is_yes "${INSTALL_SPOTIFY}"; then
    info "Instalando Spotify..."
    install_aur spotify
    tracker_mark_installed "INSTALL_SPOTIFY" "y"
    success "Spotify instalado"
fi

if is_yes "${INSTALL_OBS}"; then
    info "Instalando OBS Studio..."
    install_pkg obs-studio
    tracker_mark_installed "INSTALL_OBS" "y"
    success "OBS instalado"
fi

# ============================================
# TERMINALES
# ============================================

if is_yes "${INSTALL_KITTY}"; then
    info "Instalando kitty..."
    install_pkg kitty kitty-terminfo
    tracker_mark_installed "INSTALL_KITTY" "y"
    success "kitty instalado"
fi

if is_yes "${INSTALL_ALACRITTY}"; then
    info "Instalando alacritty..."
    install_pkg alacritty
    tracker_mark_installed "INSTALL_ALACRITTY" "y"
    success "alacritty instalado"
fi

# ============================================
# DESARROLLO
# ============================================

if is_yes "${INSTALL_DOCKER}"; then
    info "Instalando Docker..."
    install_pkg docker docker-compose
    systemctl enable docker
    usermod -aG docker "$PI_REAL_USER" 2>/dev/null || true
    tracker_mark_installed "INSTALL_DOCKER" "y"
    success "Docker instalado"
fi

if is_yes "${INSTALL_NODEJS}"; then
    info "Instalando Node.js..."
    install_pkg nodejs npm
    sudo -u "$PI_REAL_USER" bash -c "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash" 2>/dev/null || true
    tracker_mark_installed "INSTALL_NODEJS" "y"
    success "Node.js instalado"
fi

if is_yes "${INSTALL_PYTHON}"; then
    info "Instalando Python completo..."
    install_pkg \
        python \
        python-pip \
        python-virtualenv \
        python-pipx \
        ipython \
        python-poetry \
        python-pyenv
    tracker_mark_installed "INSTALL_PYTHON" "y"
    success "Python instalado"
fi

success "Módulo Software Esencial completado"
