#!/bin/bash
# Módulo 05: Software Adicional y Herramientas CLI Modernas

set -e
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/pi-linux-common.sh"

banner "Módulo 05: Herramientas CLI, Editores y Shells"

# Backup de .bashrc si no existe backup previo
if [[ -f "${PI_USER_HOME}/.bashrc" && ! -f "${PI_USER_HOME}/.bashrc.pilinux.bak" ]]; then
    cp "${PI_USER_HOME}/.bashrc" "${PI_USER_HOME}/.bashrc.pilinux.bak"
    info "Backup de .bashrc creado: .bashrc.pilinux.bak"
fi

# Limpiar configuraciones previas de pi-linux para evitar duplicados
if [[ -f "${PI_USER_HOME}/.bashrc" ]]; then
    sed -i '/# >>> pi-linux config begin/,/# <<< pi-linux config end/d' "${PI_USER_HOME}/.bashrc"
fi

# Preparar bloque de configuración
BASHRC_BLOCK="${PI_USER_HOME}/.bashrc"
{
    echo ""
    echo "# >>> pi-linux config begin"
    echo "# Esta sección fue añadida por Pi-Linux. Puedes eliminarla si lo deseas."
} >> "$BASHRC_BLOCK"

# ============================================
# HERRAMIENTAS CLI MODERNAS
# ============================================

info "Instalando herramientas CLI modernas..."

if is_yes "${INSTALL_FZF}"; then
    install_pkg fzf
    if ! grep -q 'fzf --bash' "${PI_USER_HOME}/.bashrc" 2>/dev/null; then
        echo 'eval "$(fzf --bash)"' >> "$BASHRC_BLOCK"
    fi
    tracker_mark_installed "INSTALL_FZF" "y"
fi

if is_yes "${INSTALL_RIPGREP}"; then
    install_pkg ripgrep
    tracker_mark_installed "INSTALL_RIPGREP" "y"
fi

if is_yes "${INSTALL_FD}"; then
    install_pkg fd
    tracker_mark_installed "INSTALL_FD" "y"
fi

if is_yes "${INSTALL_BAT}"; then
    install_pkg bat
    if ! grep -q 'alias cat=' "${PI_USER_HOME}/.bashrc" 2>/dev/null; then
        echo 'alias catb="bat --style=plain"' >> "$BASHRC_BLOCK"
    fi
    tracker_mark_installed "INSTALL_BAT" "y"
fi

if is_yes "${INSTALL_EZA}"; then
    install_pkg eza
    if ! grep -q 'alias ls=' "${PI_USER_HOME}/.bashrc" 2>/dev/null; then
        echo 'alias ls="eza --icons"' >> "$BASHRC_BLOCK"
        echo 'alias ll="eza -la --icons"' >> "$BASHRC_BLOCK"
        echo 'alias la="eza -a --icons"' >> "$BASHRC_BLOCK"
        echo 'alias tree="eza --tree --icons"' >> "$BASHRC_BLOCK"
    fi
    tracker_mark_installed "INSTALL_EZA" "y"
fi

if is_yes "${INSTALL_ZOXIDE}"; then
    install_pkg zoxide
    if ! grep -q 'zoxide init bash' "${PI_USER_HOME}/.bashrc" 2>/dev/null; then
        echo 'eval "$(zoxide init bash)"' >> "$BASHRC_BLOCK"
        echo 'alias zz="z"' >> "$BASHRC_BLOCK"
    fi
    tracker_mark_installed "INSTALL_ZOXIDE" "y"
fi

if is_yes "${INSTALL_ATUIN}"; then
    info "Instalando Atuin..."
    if timeout 120 curl --proto '=https' --tlsv1.2 -LsSf -m 60 -o /tmp/atuin_install.sh https://setup.atuin.sh 2>/dev/null; then
        if sudo -u "$PI_REAL_USER" sh /tmp/atuin_install.sh 2>/dev/null; then
            tracker_mark_installed "INSTALL_ATUIN" "y"
            success "Atuin instalado"
        else
            warning "No se pudo ejecutar el instalador de Atuin"
        fi
    else
        warning "No se pudo descargar Atuin (timeout red)"
    fi
fi

if is_yes "${INSTALL_DELTA}"; then
    install_pkg git-delta
    tracker_mark_installed "INSTALL_DELTA" "y"
fi

success "Herramientas CLI instaladas"

# ============================================
# EDITORES
# ============================================

if is_yes "${INSTALL_NEOVIM}"; then
    info "Instalando Neovim..."
    install_pkg neovim
    install_pkg nodejs npm python-pynvim luarocks tree-sitter-cli
    tracker_mark_installed "INSTALL_NEOVIM" "y"
    success "Neovim instalado"
fi

if is_yes "${INSTALL_LAZYVIM}"; then
    info "Instalando LazyVim..."
    pi_backup "${PI_USER_HOME}/.config/nvim"
    pi_backup "${PI_USER_HOME}/.local/share/nvim"
    pi_backup "${PI_USER_HOME}/.local/state/nvim"
    pi_backup "${PI_USER_HOME}/.cache/nvim"
    
    sudo -u "$PI_REAL_USER" GIT_TERMINAL_PROMPT=0 timeout 120 git clone https://github.com/LazyVim/starter "${PI_USER_HOME}/.config/nvim" 2>/dev/null || warning "No se pudo clonar LazyVim starter"
    rm -rf "${PI_USER_HOME}/.config/nvim/.git"
    chown -R "${PI_REAL_USER}:${PI_REAL_USER}" "${PI_USER_HOME}/.config/nvim"
    tracker_mark_installed "INSTALL_LAZYVIM" "y"
    success "LazyVim instalado"
fi

if is_yes "${INSTALL_DOOMEMACS}"; then
    info "Instalando Doom Emacs..."
    install_pkg emacs
    sudo -u "$PI_REAL_USER" GIT_TERMINAL_PROMPT=0 timeout 120 git clone --depth 1 https://github.com/doomemacs/doomemacs "${PI_USER_HOME}/.config/emacs" 2>/dev/null || {
        warning "No se pudo clonar Doom Emacs"
        return 0
    }
    # doom install puede ser muy largo y promptear; forzar no-confirm no es trivial,
    # así que usamos timeout generoso y stdin desde /dev/null
    if ! timeout 600 sudo -u "$PI_REAL_USER" "${PI_USER_HOME}/.config/emacs/bin/doom" install --force < /dev/null 2>/dev/null; then
        warning "Doom install falló o excedió tiempo límite (10 min)"
    fi
    sudo -u "$PI_REAL_USER" "${PI_USER_HOME}/.config/emacs/bin/doom" install
    tracker_mark_installed "INSTALL_DOOMEMACS" "y"
    success "Doom Emacs instalado"
fi

# ============================================
# MONITORES
# ============================================

if is_yes "${INSTALL_BTOP}"; then
    info "Instalando btop..."
    install_pkg btop
    mkdir -p "${PI_USER_HOME}/.config/btop"
    chown -R "${PI_REAL_USER}:${PI_REAL_USER}" "${PI_USER_HOME}/.config/btop"
    tracker_mark_installed "INSTALL_BTOP" "y"
    success "btop instalado"
fi

if is_yes "${INSTALL_NVTOP}"; then
    info "Instalando nvtop..."
    install_pkg nvtop
    tracker_mark_installed "INSTALL_NVTOP" "y"
    success "nvtop instalado"
fi

# ============================================
# SHELLS
# ============================================

if is_yes "${INSTALL_ZSH}"; then
    info "Instalando Zsh..."
    install_pkg zsh zsh-completions zsh-syntax-highlighting zsh-autosuggestions
    if [[ "${PI_SKIP_CHSH:-n}" != "y" ]]; then
        info "Cambiando shell por defecto a Zsh..."
        chsh -s /bin/zsh "$PI_REAL_USER" 2>/dev/null || true
    else
        info "Saltando cambio de shell (PI_SKIP_CHSH=y)"
    fi
    tracker_mark_installed "INSTALL_ZSH" "y"
    success "Zsh instalado"
fi

if is_yes "${INSTALL_OHMYZSH}"; then
    info "Instalando Oh-My-Zsh..."
    if timeout 120 curl -fsSL -m 60 -o /tmp/ohmyzsh_install.sh https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh 2>/dev/null; then
        sudo -u "$PI_REAL_USER" sh /tmp/ohmyzsh_install.sh "" --unattended
    else
        warning "No se pudo descargar Oh-My-Zsh (timeout red)"
    fi
    
    # Plugins adicionales
    sudo -u "$PI_REAL_USER" GIT_TERMINAL_PROMPT=0 timeout 60 git clone https://github.com/zsh-users/zsh-autosuggestions "${PI_USER_HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions" 2>/dev/null || true
    sudo -u "$PI_REAL_USER" GIT_TERMINAL_PROMPT=0 timeout 60 git clone https://github.com/zsh-users/zsh-syntax-highlighting "${PI_USER_HOME}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" 2>/dev/null || true
    sudo -u "$PI_REAL_USER" GIT_TERMINAL_PROMPT=0 timeout 60 git clone https://github.com/zdharma-continuum/fast-syntax-highlighting "${PI_USER_HOME}/.oh-my-zsh/custom/plugins/fast-syntax-highlighting" 2>/dev/null || true
    
    tracker_mark_installed "INSTALL_OHMYZSH" "y"
    success "Oh-My-Zsh instalado"
fi

if is_yes "${INSTALL_FISH}"; then
    info "Instalando Fish..."
    install_pkg fish
    tracker_mark_installed "INSTALL_FISH" "y"
    success "Fish instalado"
fi

if is_yes "${INSTALL_STARSHIP}"; then
    info "Instalando Starship..."
    if timeout 120 curl -fsSL -m 60 -o /tmp/starship_install.sh https://starship.rs/install.sh 2>/dev/null; then
        sh /tmp/starship_install.sh -y
    else
        warning "No se pudo descargar Starship (timeout red)"
    fi
    if ! grep -q 'starship init bash' "${PI_USER_HOME}/.bashrc" 2>/dev/null; then
        echo 'eval "$(starship init bash)"' >> "$BASHRC_BLOCK"
    fi
    mkdir -p "${PI_USER_HOME}/.config"
    sudo -u "$PI_REAL_USER" starship preset pure-preset -o "${PI_USER_HOME}/.config/starship.toml" 2>/dev/null || true
    chown -R "${PI_REAL_USER}:${PI_REAL_USER}" "${PI_USER_HOME}/.config"
    tracker_mark_installed "INSTALL_STARSHIP" "y"
    success "Starship instalado"
fi

# ============================================
# TMUX
# ============================================

if is_yes "${INSTALL_TMUX}"; then
    info "Instalando tmux..."
    install_pkg tmux
    tracker_mark_installed "INSTALL_TMUX" "y"
    success "tmux instalado"
fi

if is_yes "${INSTALL_OHMYTMUX}"; then
    info "Instalando Oh-My-Tmux..."
    sudo -u "$PI_REAL_USER" GIT_TERMINAL_PROMPT=0 timeout 120 git clone https://github.com/gpakosz/.tmux.git "${PI_USER_HOME}/.tmux" 2>/dev/null || warning "No se pudo clonar Oh-My-Tmux"
    sudo -u "$PI_REAL_USER" ln -s -f "${PI_USER_HOME}/.tmux/.tmux.conf" "${PI_USER_HOME}/.tmux.conf"
    sudo -u "$PI_REAL_USER" cp "${PI_USER_HOME}/.tmux/.tmux.conf.local" "${PI_USER_HOME}/.tmux.conf.local" 2>/dev/null || true
    tracker_mark_installed "INSTALL_OHMYTMUX" "y"
    success "Oh-My-Tmux instalado"
fi

{
    echo "# <<< pi-linux config end"
} >> "$BASHRC_BLOCK"

success "Módulo Software Adicional completado"
