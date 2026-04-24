#!/bin/bash
# Pi-Linux Module: Download Organizer
# Automatically sorts downloaded files into categorized folders
# https://github.com/Pinedux/pi-linux
# License: GPL-3.0

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/pi-linux-common.sh"

MODULE_NAME="download-organizer"
LOCAL_SCRIPTS_DIR="/usr/share/pi-linux/scripts"

echo "========================================"
echo "  [$MODULE_NAME] Organizador de Descargas"
echo "========================================"
echo ""

# Check if already installed
if tracker_is_installed "$MODULE_NAME"; then
    echo "[$MODULE_NAME] Ya instalado. Omitiendo..."
    exit 0
fi

# Install inotify-tools (required for file monitoring)
echo "[*] Instalando inotify-tools..."
install_pkg inotify-tools

# Create user directories and install script for the main user
# Note: This runs during installation as root, so we set up for the target user
if [[ -n "${PI_USERNAME:-}" ]]; then
    USER_HOME="/home/$PI_USERNAME"
    USER_NAME="$PI_USERNAME"
else
    # Fallback: detect first non-system user with home directory
    USER_NAME="$(awk -F: '$3 >= 1000 && $3 < 65534 {print $1; exit}' /etc/passwd)"
    USER_HOME="$(getent passwd "$USER_NAME" | cut -d: -f6)"
fi

if [[ -z "$USER_NAME" || ! -d "$USER_HOME" ]]; then
    echo "[!] No se encontró usuario objetivo. Saltando configuración de usuario."
    tracker_mark_installed "$MODULE_NAME"
    exit 0
fi

echo "[*] Configurando organizador para usuario: $USER_NAME"

# Create user directories
mkdir -p "$USER_HOME/.local/bin"
mkdir -p "$USER_HOME/.local/share/pi-linux"
mkdir -p "$USER_HOME/.config/systemd/user"
mkdir -p "$USER_HOME/Descargas"

# Create categorized folders
mkdir -p "$USER_HOME/Descargas/Documentos"
mkdir -p "$USER_HOME/Descargas/Imagenes"
mkdir -p "$USER_HOME/Descargas/Videos"
mkdir -p "$USER_HOME/Descargas/Musica"
mkdir -p "$USER_HOME/Descargas/Comprimidos"
mkdir -p "$USER_HOME/Descargas/Aplicaciones"
mkdir -p "$USER_HOME/Descargas/Otros"

# Install organizer script
if [[ -f "${LOCAL_SCRIPTS_DIR}/download-organizer.sh" ]]; then
    cp -v "${LOCAL_SCRIPTS_DIR}/download-organizer.sh" "$USER_HOME/.local/bin/pi-linux-download-organizer"
else
    echo "[!] Script del organizador no encontrado en medios locales. Descargando..."
    if ! timeout 60 curl -fsSL -m 30 -o "$USER_HOME/.local/bin/pi-linux-download-organizer" \
        "https://raw.githubusercontent.com/Pinedux/pi-linux/main/scripts/download-organizer.sh" 2>/dev/null; then
        error "No se pudo descargar el script del organizador"
        return 1
    fi
fi

chmod +x "$USER_HOME/.local/bin/pi-linux-download-organizer"

# Install systemd user service
if [[ -f "${LOCAL_SCRIPTS_DIR}/download-organizer.service" ]]; then
    cp -v "${LOCAL_SCRIPTS_DIR}/download-organizer.service" "$USER_HOME/.config/systemd/user/"
else
    cat > "$USER_HOME/.config/systemd/user/download-organizer.service" << 'EOF'
[Unit]
Description=Pi-Linux Download Organizer
Documentation=https://github.com/Pinedux/pi-linux
After=graphical-session.target

[Service]
Type=simple
ExecStart=%h/.local/bin/pi-linux-download-organizer
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
EOF
fi

# Fix ownership only for files/directories we created (avoid excessive chown)
chown -R "$USER_NAME:$USER_NAME" "$USER_HOME/.local/share/pi-linux"
chown -R "$USER_NAME:$USER_NAME" "$USER_HOME/.local/bin/pi-linux-download-organizer"
chown -R "$USER_NAME:$USER_NAME" "$USER_HOME/.config/systemd/user/download-organizer.service"
chown -R "$USER_NAME:$USER_NAME" "$USER_HOME/Descargas"

# Enable and start service as user
sudo -u "$USER_NAME" systemctl --user daemon-reload
sudo -u "$USER_NAME" systemctl --user enable download-organizer.service
sudo -u "$USER_NAME" systemctl --user start download-organizer.service || true

echo ""
echo "[✓] Organizador de descargas instalado y activado."
echo "    Usuario: $USER_NAME"
echo "    Script: ~/.local/bin/pi-linux-download-organizer"
echo "    Estado: systemctl --user status download-organizer"
echo "    Log: ~/.local/share/pi-linux/download-organizer.log"
echo ""
echo "    Carpetas creadas en ~/Descargas:"
echo "      📄 Documentos  |  🖼️ Imagenes  |  🎬 Videos"
echo "      🎵 Musica      |  📦 Comprimidos |  💻 Aplicaciones"
echo "      📂 Otros"
echo ""

tracker_mark_installed "$MODULE_NAME"
