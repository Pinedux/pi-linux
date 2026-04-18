#!/bin/bash
# Pi-Linux First Boot Installer v2.0
# Se ejecuta automáticamente en el primer boot del sistema instalado

set -e
set -o pipefail

INSTALL_MARKER="/var/lib/pi-linux-installed"
REPO_URL="https://github.com/Pinedux/pi-linux.git"
LOCAL_DIR="/usr/share/pi-linux"
INSTALL_DIR="/tmp/pi-linux"

# Si ya se completó, salir
if [[ -f "$INSTALL_MARKER" ]]; then
    grep -q "STATUS=completed" "$INSTALL_MARKER" 2>/dev/null && exit 0
fi

# Marcar inicio para evitar loops infinitos pero permitir reintentos
mkdir -p "$(dirname "$INSTALL_MARKER")"
echo "STATUS=in_progress" > "$INSTALL_MARKER"

# Esperar a que haya red
info_wait() {
    echo "[*] Esperando conexión a internet..."
    for i in {1..60}; do
        if ping -c 1 archlinux.org &>/dev/null; then
            echo "[✓] Conexión OK"
            return 0
        fi
        echo "[$i/60] Esperando..."
        sleep 2
    done
    return 1
}

on_error() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  ⚠  La instalación no pudo completarse."
    echo ""
    echo "  1) Reintentar (requiere internet)"
    echo "  2) Abrir shell para diagnóstico manual"
    echo "  3) Saltar y continuar al login"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    read -rp "Selecciona [1-3]: " choice
    case "$choice" in
        1) exec "$0" ;;
        2) bash ;;
        3)
            echo "STATUS=skipped" > "$INSTALL_MARKER"
            exit 0
            ;;
        *) exec "$0" ;;
    esac
}

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

# Verificar red
if ! info_wait; then
    echo "⚠  No hay conexión a internet."
    on_error
fi

# Preferir scripts locales (offline) si existen
if [[ -d "$LOCAL_DIR" && -f "$LOCAL_DIR/scripts/tui.sh" ]]; then
    echo "[*] Usando scripts locales (offline)..."
    INSTALL_DIR="$LOCAL_DIR"
else
    # Clonar repo
    if [[ -d "$INSTALL_DIR" ]]; then
        rm -rf "$INSTALL_DIR"
    fi
    
    echo "[*] Descargando Pi-Linux..."
    if ! timeout 120 git clone --depth 1 "$REPO_URL" "$INSTALL_DIR" 2>/dev/null; then
        echo "⚠  No se pudo descargar. Asegúrate de tener internet."
        echo "   Puedes ejecutar manualmente después:"
        echo "   bash <(curl -sL https://raw.githubusercontent.com/Pinedux/pi-linux/main/scripts/tui.sh)"
        on_error
    fi
fi

echo "[*] Iniciando instalador TUI..."
cd "$INSTALL_DIR"
chmod +x scripts/tui.sh

# Ejecutar TUI con trap para capturar errores
if bash scripts/tui.sh; then
    echo "STATUS=completed" > "$INSTALL_MARKER"
    echo ""
    echo "✅ Pi-Linux First Boot completado."
    echo "   Reiniciando en 5 segundos..."
    echo ""
    sleep 5
    systemctl reboot
else
    echo "⚠  El instalador TUI falló."
    on_error
fi
