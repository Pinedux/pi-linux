#!/bin/bash
# Script de recuperación - Restaura todos los archivos desde modules-setup.sh
# Ejecutar: bash RESTORE.sh

set -e

echo "=============================================="
echo "  🔧 RESTAURACIÓN DE PI-LINUX"
echo "=============================================="
echo ""

# Directorio destino
INSTALL_DIR="$HOME/pi-linux"
SOURCE_FILE="$HOME/www/pi_linux/modules-setup.sh"

if [[ ! -f "$SOURCE_FILE" ]]; then
    echo "❌ No se encontró: $SOURCE_FILE"
    exit 1
fi

echo "📂 Origen: $SOURCE_FILE"
echo "📂 Destino: $INSTALL_DIR"
echo ""

# Crear directorios
mkdir -p "$INSTALL_DIR"/{modules,config,scripts,themes}

# ============================================
# EXTRAER Y CREAR MÓDULOS
# ============================================

echo "🔨 Extrayendo módulos..."

# Función para extraer sección del archivo
extract_section() {
    local start_marker="$1"
    local end_marker="$2"
    local output_file="$3"
    
    sed -n "/$start_marker/,/$end_marker/p" "$SOURCE_FILE" | \
    sed "1d;$d" > "$output_file"
    
    chmod +x "$output_file"
    echo "  ✓ $output_file"
}

# Extraer cada módulo
extract_section "MÓDULO 02: GPU" "^EOF$" "$INSTALL_DIR/modules/02-gpu.sh"
extract_section "MÓDULO 03: Desktop" "^EOF$" "$INSTALL_DIR/modules/03-desktop.sh"
extract_section "MÓDULO 04: Temas" "^EOF$" "$INSTALL_DIR/modules/04-themes.sh"
extract_section "MÓDULO 05: Software" "^EOF$" "$INSTALL_DIR/modules/05-software.sh"
extract_section "MÓDULO 06: Dotfiles" "^EOF$" "$INSTALL_DIR/modules/06-dotfiles.sh"

echo ""
echo "✅ Módulos extraídos correctamente"
echo ""

# ============================================
# CREAR MÓDULOS 00 Y 01
# ============================================

echo "🔨 Creando módulos base..."

cat > "$INSTALL_DIR/modules/00-preinstall.sh" << 'MOD00'
#!/bin/bash
set -e
echo "[00] Actualizando sistema..."
pacman -Syu --noconfirm
echo "[✓] Sistema actualizado"
MOD00

cat > "$INSTALL_DIR/modules/01-base.sh" << 'MOD01'
#!/bin/bash
set -e
echo "[01] Instalando sistema base..."
pacman -S --needed --noconfirm \
    networkmanager git wget curl base-devel
systemctl enable NetworkManager
echo "[✓] Base instalada"
MOD01

chmod +x "$INSTALL_DIR/modules/00-preinstall.sh"
chmod +x "$INSTALL_DIR/modules/01-base.sh"
echo "  ✓ Módulos 00 y 01 creados"

# Eliminar archivo duplicado si existe
if [[ -f "$INSTALL_DIR/modules/04-software.sh" ]] && [[ $(wc -l < "$INSTALL_DIR/modules/04-software.sh") -lt 20 ]]; then
    rm "$INSTALL_DIR/modules/04-software.sh"
    echo "  ✓ Archivo duplicado 04-software.sh eliminado"
fi

echo ""
echo "=============================================="
echo "  ✅ RESTAURACIÓN COMPLETADA"
echo "=============================================="
echo ""
echo "Módulos restaurados:"
ls -la "$INSTALL_DIR/modules/"
