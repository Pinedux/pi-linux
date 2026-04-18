#!/bin/bash
# Pi-Linux First Boot Installer
# Se ejecuta automáticamente en el primer boot del sistema instalado
# Estrategia 2: Post-instalación automática después de Arch base

set -e

INSTALL_MARKER="/var/lib/pi-linux-installed"
REPO_URL="https://github.com/Pinedux/pi-linux.git"
INSTALL_DIR="/tmp/pi-linux"

# Si ya se ejecutó, salir
if [[ -f "$INSTALL_MARKER" ]]; then
    exit 0
fi

# Esperar a que haya red
for i in {1..30}; do
    if ping -c 1 archlinux.org &>/dev/null; then
        break
    fi
    echo "[$i/30] Esperando conexión a internet..."
    sleep 2
done

clear
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "    🥧  Pi-Linux First Boot Installer"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Este sistema tiene Arch Linux base instalado."
echo "Pi-Linux configurará tu escritorio automáticamente."
echo ""

# Clonar repo
if [[ -d "$INSTALL_DIR" ]]; then
    rm -rf "$INSTALL_DIR"
fi

echo "[*] Descargando Pi-Linux..."
if ! git clone --depth 1 "$REPO_URL" "$INSTALL_DIR" 2>/dev/null; then
    echo "⚠  No se pudo descargar. Asegúrate de tener internet."
    echo "   Puedes ejecutar manualmente después:"
    echo "   bash <(curl -sL https://raw.githubusercontent.com/Pinedux/pi-linux/main/scripts/tui.sh)"
    exit 1
fi

echo "[*] Iniciando instalador TUI..."
cd "$INSTALL_DIR"
chmod +x scripts/tui.sh

# Ejecutar TUI
bash scripts/tui.sh

# Marcar como instalado
mkdir -p "$(dirname "$INSTALL_MARKER")"
touch "$INSTALL_MARKER"

echo ""
echo "✅ Pi-Linux First Boot completado."
echo "   Reiniciando en 5 segundos..."
echo ""
sleep 5
systemctl reboot
