#!/bin/bash
# Módulo 01: Sistema Base

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/pi-linux-common.sh"

banner "Módulo 01: Sistema Base"

info "Instalando paquetes base..."

install_pkg \
    base-devel \
    git \
    curl \
    wget \
    linux-headers \
    networkmanager \
    iwd \
    pipewire \
    pipewire-pulse \
    pipewire-alsa \
    wireplumber \
    noto-fonts \
    noto-fonts-emoji \
    noto-fonts-cjk \
    papirus-icon-theme

# Configure NetworkManager to use iwd (faster, more reliable than wpa_supplicant)
mkdir -p /etc/NetworkManager/NetworkManager.conf.d
cat > /etc/NetworkManager/NetworkManager.conf.d/wifi_backend.conf << 'EOF'
[device]
wifi.backend=iwd
EOF

systemctl enable NetworkManager
systemctl --global enable pipewire pipewire-pulse wireplumber 2>/dev/null || true

success "Sistema base instalado"
