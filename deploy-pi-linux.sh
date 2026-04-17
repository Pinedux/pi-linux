#!/bin/bash
# Pi-Linux Deploy Script v2.0
# Este script despliega el instalador completo en ~/www/pi_linux

set -e

INSTALL_DIR="${HOME}/www/pi_linux"

# Directorio donde está este script
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                                                              ║"
echo "║    🥧  Pi-Linux Installer Builder v2.0                       ║"
echo "║       Instalador automático para Arch Linux                  ║"
echo "║       Con rices completos: HyDE · WhiteSur · Sweet           ║"
echo "║                                                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Este script sincronizará el instalador en: $INSTALL_DIR"
echo ""
read -rp "¿Continuar? [S/n]: " confirm

if [[ "$confirm" == "n" || "$confirm" == "N" ]]; then
    echo "Cancelado."
    exit 0
fi

# Crear directorios
echo "[*] Creando estructura de directorios..."
mkdir -p "$INSTALL_DIR"/{modules,config,lib,scripts}

# ============================================
# COPIAR ARCHIVOS DEL REPO
# ============================================

echo "[*] Copiando archivos del proyecto..."

# Script principal
cp "$SRC_DIR/pi-linux.sh" "$INSTALL_DIR/pi-linux.sh"
chmod +x "$INSTALL_DIR/pi-linux.sh"
echo "  ✓ pi-linux.sh"

# Librería común
cp "$SRC_DIR/lib/pi-linux-common.sh" "$INSTALL_DIR/lib/pi-linux-common.sh"
echo "  ✓ lib/pi-linux-common.sh"

# Módulos
for mod in "$SRC_DIR"/modules/*.sh; do
    if [[ -f "$mod" ]]; then
        cp "$mod" "$INSTALL_DIR/modules/$(basename "$mod")"
        chmod +x "$INSTALL_DIR/modules/$(basename "$mod")"
        echo "  ✓ modules/$(basename "$mod")"
    fi
done

# Configuración
cp "$SRC_DIR/config/unattended.conf" "$INSTALL_DIR/config/unattended.conf"
echo "  ✓ config/unattended.conf"

# README
if [[ -f "$SRC_DIR/README.md" ]]; then
    cp "$SRC_DIR/README.md" "$INSTALL_DIR/README.md"
    echo "  ✓ README.md"
fi

# Scripts auxiliares
if [[ -d "$SRC_DIR/scripts" ]]; then
    for script in "$SRC_DIR"/scripts/*; do
        if [[ -f "$script" ]]; then
            cp "$script" "$INSTALL_DIR/scripts/$(basename "$script")"
            chmod +x "$INSTALL_DIR/scripts/$(basename "$script")" 2>/dev/null || true
            echo "  ✓ scripts/$(basename "$script")"
        fi
    done
fi

echo ""
echo "========================================"
echo "  ✅ Pi-Linux v2.0 desplegado!"
echo "========================================"
echo ""
echo "📂 Ubicación: $INSTALL_DIR"
echo ""
echo "🚀 Para comenzar:"
echo "    cd $INSTALL_DIR"
echo "    sudo ./pi-linux.sh"
echo ""
echo "📖 Modo desatendido:"
echo "    sudo ./pi-linux.sh --unattended"
echo ""
echo "🎨 Modo Rice Express:"
echo "    sudo ./pi-linux.sh  →  Opción 3"
echo ""
