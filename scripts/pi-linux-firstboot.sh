#!/bin/bash
# Pi-Linux First Boot Installer v2.1
# Se ejecuta automaticamente en el primer boot del sistema instalado

set -o pipefail

INSTALL_MARKER="/var/lib/pi-linux-installed"
REPO_URL="https://github.com/Pinedux/pi-linux.git"
LOCAL_DIR="/usr/share/pi-linux"
INSTALL_DIR="/tmp/pi-linux"

# Si ya se completo, salir
if [[ -f "$INSTALL_MARKER" ]]; then
    grep -q "STATUS=completed" "$INSTALL_MARKER" 2>/dev/null && exit 0
fi

# Marcar inicio para evitar loops infinitos pero permitir reintentos
mkdir -p "$(dirname "$INSTALL_MARKER")"
echo "STATUS=in_progress" > "$INSTALL_MARKER"

clear
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "    🥧  Pi-Linux First Boot Installer"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Este sistema tiene Arch Linux base instalado."
echo "Pi-Linux configurara tu escritorio automaticamente."
echo ""

# Funcion de error
on_error() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  ⚠  La instalacion no pudo completarse."
    echo ""
    echo "  1) Reintentar"
    echo "  2) Abrir shell para diagnostico manual"
    echo "  3) Saltar y continuar al login"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    read -rp "Selecciona [1-3]: " choice
    case "$choice" in
        1) exec "$0" ;;
        2) bash; exec "$0" ;;
        3)
            echo "STATUS=skipped" > "$INSTALL_MARKER"
            exit 0
            ;;
        *) exec "$0" ;;
    esac
}

# Preferir scripts locales (offline) si existen
if [[ -d "$LOCAL_DIR" && -f "$LOCAL_DIR/pi-linux.sh" ]]; then
    echo "[*] Usando scripts locales (offline)..."
    INSTALL_DIR="$LOCAL_DIR"
else
    # Verificar red antes de intentar descargar
    echo "[*] Esperando conexion a internet..."
    for i in {1..60}; do
        if ping -c 1 archlinux.org &>/dev/null; then
            echo "[✓] Conexion OK"
            break
        fi
        echo "[$i/60] Esperando..."
        sleep 2
        if [[ $i -eq 60 ]]; then
            echo "⚠  No hay conexion a internet y no hay scripts locales."
            on_error
        fi
    done

    # Clonar repo
    if [[ -d "$INSTALL_DIR" ]]; then
        rm -rf "$INSTALL_DIR"
    fi

    echo "[*] Descargando Pi-Linux..."
    if ! timeout 120 git clone --depth 1 "$REPO_URL" "$INSTALL_DIR" 2>/dev/null; then
        echo "⚠  No se pudo descargar. Asegurate de tener internet."
        on_error
    fi
fi

cd "$INSTALL_DIR" || on_error
chmod +x pi-linux.sh 2>/dev/null || true

# Si hay configuracion desatendida, usar modo automatico
if [[ -f "$INSTALL_DIR/config/unattended.conf" ]]; then
    echo "[*] Ejecutando instalacion desatendida..."
    if bash "$INSTALL_DIR/pi-linux.sh" --unattended --yes; then
        echo "STATUS=completed" > "$INSTALL_MARKER"
        echo ""
        echo "✅ Pi-Linux First Boot completado."
        echo "   Reiniciando en 5 segundos..."
        sleep 5
        systemctl reboot || true
    else
        echo "⚠  La instalacion desatendida fallo."
        on_error
    fi
else
    # Fallback a TUI interactivo
    if [[ -f "$INSTALL_DIR/scripts/tui.sh" ]]; then
        chmod +x "$INSTALL_DIR/scripts/tui.sh"
        echo "[*] Iniciando instalador TUI..."
        if bash "$INSTALL_DIR/scripts/tui.sh"; then
            echo "STATUS=completed" > "$INSTALL_MARKER"
            echo ""
            echo "✅ Pi-Linux First Boot completado."
            echo "   Reiniciando en 5 segundos..."
            sleep 5
            systemctl reboot || true
        else
            echo "⚠  El instalador TUI fallo."
            on_error
        fi
    else
        echo "⚠  No se encontro ni unattended.conf ni tui.sh"
        on_error
    fi
fi
