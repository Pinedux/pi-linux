#!/bin/bash
# Pi-Linux Module: keyd-remapper installation
# GUI for remapping keyboards using the keyd daemon
# https://github.com/Pinedux/keyd-remapper
# License: GPL-3.0

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/pi-linux-common.sh"

MODULE_NAME="keyd-remapper"
APP_IMAGE="keyd-remapper-x86_64.AppImage"
LOCALExtras_DIR="/usr/share/pi-linux/extras"
INSTALL_DIR="/opt/keyd-remapper"

echo "========================================"
echo "  [$MODULE_NAME] Keyd Remapper"
echo "========================================"
echo ""

# Check if already installed
if tracker_is_installed "$MODULE_NAME"; then
    echo "[$MODULE_NAME] Ya instalado. Omitiendo..."
    exit 0
fi

# Install keyd daemon (required runtime dependency)
echo "[*] Instalando keyd daemon..."
install_pkg keyd fuse2

# Ensure keyd service is enabled and started
systemctl enable keyd.service --now 2>/dev/null || true

# Create installation directory
mkdir -p "$INSTALL_DIR"

# Look for local AppImage first (offline ISO support)
local_appimage="${LOCALExtras_DIR}/${APP_IMAGE}"
if [[ -f "$local_appimage" ]]; then
    echo "[*] Copiando AppImage desde medios locales..."
    cp -v "$local_appimage" "${INSTALL_DIR}/${APP_IMAGE}"
else
    echo "[*] Descargando keyd-remapper AppImage..."
    if ! timeout 120 curl -fsSL -m 60 -o "${INSTALL_DIR}/${APP_IMAGE}" \
        "https://github.com/Pinedux/keyd-remapper/releases/download/v1.0.1/${APP_IMAGE}" 2>/dev/null; then
        error "No se pudo descargar keyd-remapper AppImage"
        return 1
    fi
fi

chmod +x "${INSTALL_DIR}/${APP_IMAGE}"

# Install icon
if [[ -f "${LOCALExtras_DIR}/keyd-remapper.png" ]]; then
    echo "[*] Instalando icono..."
    install -Dm644 "${LOCALExtras_DIR}/keyd-remapper.png" \
        /usr/share/pixmaps/keyd-remapper.png
else
    # Fallback: download icon
    echo "[*] Descargando icono..."
    if ! timeout 60 curl -fsSL -m 30 -o /usr/share/pixmaps/keyd-remapper.png \
        "https://raw.githubusercontent.com/Pinedux/keyd-remapper/main/src-tauri/icons/icon.png" 2>/dev/null; then
        warning "No se pudo descargar icono, continuando sin él..."
    fi
fi

# Install desktop entry
if [[ -f "${LOCALExtras_DIR}/keyd-remapper.desktop" ]]; then
    echo "[*] Instalando entrada de escritorio..."
    install -Dm644 "${LOCALExtras_DIR}/keyd-remapper.desktop" \
        /usr/share/applications/keyd-remapper.desktop
else
    cat > /usr/share/applications/keyd-remapper.desktop << 'EOF'
[Desktop Entry]
Name=Keyd Remapper
Comment=Keyboard remapping GUI using keyd
Exec=/opt/keyd-remapper/keyd-remapper-x86_64.AppImage
Icon=keyd-remapper
Type=Application
Categories=System;Settings;
Terminal=false
EOF
fi

# Update desktop database
update-desktop-database /usr/share/applications 2>/dev/null || true

echo ""
echo "[✓] keyd-remapper instalado correctamente."
echo "    Ubicación: ${INSTALL_DIR}/${APP_IMAGE}"
echo "    keyd daemon: systemctl status keyd"
echo ""

tracker_mark_installed "$MODULE_NAME"
