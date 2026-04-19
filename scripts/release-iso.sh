#!/bin/bash
# Pi-Linux ISO Release Publisher
# Publica la ISO compilada como GitHub Release
#
# Uso:
#   ./scripts/release-iso.sh              # Publica la ISO actual
#   sudo ./build-iso.sh release           # Build + release en un paso

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(cat "${SCRIPT_DIR}/VERSION" 2>/dev/null || echo "unknown")"
ISO_NAME="pi-linux-${VERSION}-x86_64.iso"
ISO_PATH="${SCRIPT_DIR}/iso-output/${ISO_NAME}"

REPO_SLUG=""

# ============================================
# DEPENDENCIAS
# ============================================

check_deps() {
    if ! command -v gh &>/dev/null; then
        echo "❌ gh (GitHub CLI) no está instalado."
        echo "   Instálalo con: sudo pacman -S github-cli"
        exit 1
    fi

    if ! gh auth status &>/dev/null; then
        echo "❌ No estás autenticado con GitHub."
        echo "   Ejecuta: gh auth login"
        exit 1
    fi
}

get_repo_slug() {
    local remote_url
    remote_url=$(git -C "$SCRIPT_DIR" remote get-url origin 2>/dev/null || true)
    if [[ -z "$remote_url" ]]; then
        echo "❌ No se encontró remote 'origin'."
        exit 1
    fi
    # Extrae owner/repo de URLs tipo https://github.com/owner/repo.git o git@github.com:owner/repo.git
    REPO_SLUG=$(echo "$remote_url" | sed -E 's|.*github\.com[/:]([^/]+/[^/]+)(\.git)?|\1|')
}

# ============================================
# VERIFICACIÓN ISO
# ============================================

verify_iso() {
    if [[ ! -f "$ISO_PATH" ]]; then
        echo "❌ No se encontró la ISO: $ISO_PATH"
        echo "   Compila primero con: sudo ./build-iso.sh build"
        exit 1
    fi

    local size
    size=$(du -h "$ISO_PATH" | cut -f1)
    echo "📀 ISO:     $ISO_NAME"
    echo "📏 Tamaño:  $size"

    # GitHub limita archivos a 2GB
    local size_bytes
    size_bytes=$(stat -c%s "$ISO_PATH")
    if [[ "$size_bytes" -gt 2147483648 ]]; then
        echo "❌ La ISO excede el límite de 2GB de GitHub ($size_bytes bytes)"
        echo "   Considera reducir más paquetes en packages.x86_64"
        exit 1
    fi
}

calculate_checksum() {
    echo "🔐 Calculando SHA256..."
    sha256sum "$ISO_PATH" > "${ISO_PATH}.sha256"
    echo "   $(cat "${ISO_PATH}.sha256" | cut -d' ' -f1)  $ISO_NAME"
}

# ============================================
# RELEASE NOTES
# ============================================

generate_notes() {
    local iso_size
    iso_size=$(du -h "$ISO_PATH" | cut -f1)
    local iso_sha256
    iso_sha256=$(cat "${ISO_PATH}.sha256" | cut -d' ' -f1)

    cat <<EOF
## Pi-Linux v${VERSION}

### 📀 ISO Live
| Campo    | Valor |
|----------|-------|
| Archivo  | \`${ISO_NAME}\` |
| Tamaño   | ${iso_size} |
| SHA256   | \`${iso_sha256}\` |

### 🚀 Instrucciones rápidas
\`\`\`bash
# 1. Descarga la ISO desde Assets abajo
# 2. Flashea a un USB (reemplaza /dev/sdX por tu dispositivo)
sudo dd if=${ISO_NAME} of=/dev/sdX bs=4M status=progress
\`\`\`

### 🖥️ ¿Qué incluye?
- Arch Linux live con kernel Linux
- Instalador TUI automático al arrancar
- Drivers GPU (NVIDIA, AMD, Intel)
- Entornos de escritorio pre-configurados (Plasma, GNOME, Hyprland)
- keyd-remapper — GUI para remapear teclados
- Organizador de descargas automático

### 📋 Cambios
Consulta el [historial de commits](https://github.com/${REPO_SLUG}/commits/v${VERSION}) para ver todos los cambios incluidos en esta versión.
EOF
}

# ============================================
# PUBLICAR
# ============================================

publish_release() {
    local tag="v${VERSION}"

    echo ""
    echo "🚀 Preparando release ${tag} en ${REPO_SLUG}..."

    # Crear tag anotado si no existe
    if ! git -C "$SCRIPT_DIR" rev-parse "$tag" &>/dev/null; then
        echo "🏷️  Creando tag ${tag}..."
        git -C "$SCRIPT_DIR" tag -a "$tag" -m "Pi-Linux ${VERSION}"
        git -C "$SCRIPT_DIR" push origin "$tag"
    else
        echo "🏷️  Tag ${tag} ya existe."
    fi

    # Verificar si el release ya existe
    if gh release view "$tag" --repo "$REPO_SLUG" &>/dev/null; then
        echo "⚠️  El release ${tag} ya existe en GitHub."
        read -rp "   ¿Sobrescribir el asset de la ISO? [s/N]: " overwrite
        if [[ "$overwrite" != "s" && "$overwrite" != "S" ]]; then
            echo "Cancelado."
            exit 0
        fi

        echo "📤 Subiendo ISO al release existente..."
        gh release upload "$tag" "$ISO_PATH" --repo "$REPO_SLUG" --clobber
        gh release upload "$tag" "${ISO_PATH}.sha256" --repo "$REPO_SLUG" --clobber
    else
        echo "📦 Creando release ${tag}..."
        local notes_file
        notes_file="/tmp/pi-linux-release-notes-$$.md"
        generate_notes > "$notes_file"
        gh release create "$tag" \
            --repo "$REPO_SLUG" \
            --title "Pi-Linux ${VERSION}" \
            --notes-file "$notes_file" \
            "$ISO_PATH" \
            "${ISO_PATH}.sha256"
        rm -f "$notes_file"
    fi

    local release_url
    release_url="https://github.com/${REPO_SLUG}/releases/tag/${tag}"
    local direct_url
    direct_url="https://github.com/${REPO_SLUG}/releases/download/${tag}/${ISO_NAME}"

    echo ""
    echo "========================================"
    echo "  ✅ Release publicado exitosamente!"
    echo "========================================"
    echo ""
    echo "🔗 Release:  ${release_url}"
    echo "⬇️  Descarga: ${direct_url}"
    echo ""
}

# ============================================
# MAIN
# ============================================

main() {
    check_deps
    get_repo_slug
    verify_iso
    calculate_checksum
    publish_release
}

main "$@"
