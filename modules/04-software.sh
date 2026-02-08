#!/bin/bash
set -e
echo "[04] Software adicional..."
pacman -S --needed --noconfirm \
    firefox vlc \
    neovim btop \
    fzf ripgrep fd bat eza zoxide \
    zsh tmux 2>/dev/null || true
echo "[✓] Software instalado"
