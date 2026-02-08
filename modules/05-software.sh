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
