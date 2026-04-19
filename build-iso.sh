#!/bin/bash
# Pi-Linux ISO Builder
# Compila una ISO live de Arch Linux con el instalador Pi-Linux integrado

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION="$(cat "${SCRIPT_DIR}/VERSION" 2>/dev/null || echo "2.0.0")"
PROFILE_DIR="${SCRIPT_DIR}/archiso"
OUTPUT_DIR="${SCRIPT_DIR}/iso-output"
WORK_DIR="/tmp/archiso-tmp"
PACMAN_CACHE="${SCRIPT_DIR}/.pacman-cache"
FAST_BUILD=false

# ============================================
# VERIFICAR DEPENDENCIAS
# ============================================

check_deps() {
    if ! command -v mkarchiso &>/dev/null; then
        echo ""
        echo "⚠  mkarchiso no encontrado."
        echo "   Instala archiso con:"
        echo "      sudo pacman -S archiso"
        echo ""
        exit 1
    fi
    
    if [[ $EUID -ne 0 ]]; then
        echo ""
        echo "⚠  Este script debe ejecutarse como root (sudo)"
        echo ""
        exit 1
    fi
}

# ============================================
# MENÚ
# ============================================

print_banner() {
    clear 2>/dev/null || true
    echo ""
    echo "    ____  _       __    _           __  _"
    echo "   / __ \\(_)___ _/ /_  (_)_________/ /_(_)___  ___"
    echo "  / /_/ / / __ '/ __ \\/ / ___/ ___/ __/ / __ \\/ _ \\"
    echo " / ____/ / /_/ / / / / (__  |__  ) /_/ / / / /  __/"
    echo "/_/   /_/\\__, /_/ /_/_/____/____/\\__/_/_/ /_/\\___/"
    echo "        /____/"
    echo ""
    echo "    🥧  Pi-Linux ISO Builder"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# ============================================
# BUILD
# ============================================

sync_airootfs() {
    local src_dir="${SCRIPT_DIR}"
    local dst_dir="${PROFILE_DIR}/airootfs/usr/share/pi-linux"

    echo "[*] Sincronizando scripts a airootfs..."
    mkdir -p "$PACMAN_CACHE"
    mkdir -p "${dst_dir}"
    mkdir -p "${dst_dir}"/modules
    mkdir -p "${dst_dir}"/lib
    mkdir -p "${dst_dir}"/config
    mkdir -p "${dst_dir}"/scripts
    mkdir -p "${dst_dir}"/extras

    cp -v "${src_dir}/VERSION" "${dst_dir}/VERSION"
    cp -v "${src_dir}/pi-linux.sh" "${dst_dir}/pi-linux.sh"
    cp -v "${src_dir}/lib/pi-linux-common.sh" "${dst_dir}/lib/"
    cp -v "${src_dir}/config/unattended.conf" "${dst_dir}/config/"
    for script in "${src_dir}"/scripts/*; do
        cp -v "$script" "${dst_dir}/scripts/" 2>/dev/null || true
    done

    for mod in "${src_dir}"/modules/*.sh; do
        cp -v "$mod" "${dst_dir}/modules/"
    done

    # Copy extras (keyd-remapper AppImage, icons, desktop files) for offline install
    if [[ -d "${src_dir}/extras" ]]; then
        echo "[*] Sincronizando extras a airootfs..."
        cp -v "${src_dir}"/extras/* "${dst_dir}/extras/" 2>/dev/null || true
    fi

    chmod +x "${dst_dir}/pi-linux.sh"
    chmod +x "${dst_dir}/modules/"*.sh
    chmod +x "${dst_dir}/scripts/"*.sh
}

build_iso() {
    print_banner
    
    echo "[*] Perfil:   $PROFILE_DIR"
    echo "[*] Trabajo:  $WORK_DIR"
    echo "[*] Salida:   $OUTPUT_DIR"
    echo ""
    
    mkdir -p "$OUTPUT_DIR"
    
    # Limpiar trabajo anterior (salvo en modo fast)
    if [[ "$FAST_BUILD" != true ]] && [[ -d "$WORK_DIR" ]]; then
        echo "[*] Limpiando directorio de trabajo..."
        rm -rf "$WORK_DIR"
    fi
    
    echo "[*] Inyectando versión ${VERSION} en profiledef.sh..."
    sed -i "s/^iso_version=.*/iso_version=\"${VERSION}\"/" "${PROFILE_DIR}/profiledef.sh"
    
    echo "[*] Compilando ISO Pi-Linux v${VERSION} (esto puede tardar 15-30 min)..."
    echo ""
    
    sync_airootfs
    
    # Ensure persistent pacman cache directory exists inside chroot path expectations
    mkdir -p "$PACMAN_CACHE"
    
    if [[ "$FAST_BUILD" == true ]]; then
        echo "[*] Modo FAST: reutilizando work dir y sin -r"
        mkarchiso -v -w "$WORK_DIR" -o "$OUTPUT_DIR" "$PROFILE_DIR"
    else
        mkarchiso -v -r -w "$WORK_DIR" -o "$OUTPUT_DIR" "$PROFILE_DIR"
    fi
    
    echo ""
    echo "========================================"
    echo "  ✅ ISO compilada exitosamente!"
    echo "========================================"
    echo ""
    
    local iso_file
    iso_file="${OUTPUT_DIR}/pi-linux-${VERSION}-x86_64.iso"
    
    if [[ -f "$iso_file" ]]; then
        echo "📀 ISO: $iso_file"
        echo "📏 Tamaño: $(du -h "$iso_file" | cut -f1)"
        echo ""
        echo "🚀 Para probar en QEMU:"
        echo "      run_archiso -i '$iso_file'"
        echo ""
        echo "🖥️  Para probar en QEMU (UEFI):"
        echo "      run_archiso -u -i '$iso_file'"
        echo ""
        echo "💿 Para grabar en USB:"
        echo "      sudo dd if='$iso_file' of=/dev/sdX bs=4M status=progress"
    else
        echo "⚠  No se encontró el archivo ISO esperado: $iso_file"
    fi
    echo ""
}

# ============================================
# TEST
# ============================================

test_iso() {
    print_banner
    
    local iso_file
    iso_file=$(ls -1t "$OUTPUT_DIR"/*.iso 2>/dev/null | head -n 1)
    
    if [[ -z "$iso_file" ]]; then
        echo "⚠  No hay ISOs en $OUTPUT_DIR"
        echo "   Compila primero con: sudo ./build-iso.sh build"
        exit 1
    fi
    
    echo "[*] Probando ISO: $iso_file"
    echo ""
    
    read -rp "¿Modo UEFI? [s/N]: " uefi_mode
    
    if [[ "$uefi_mode" == "s" || "$uefi_mode" == "S" ]]; then
        run_archiso -u -i "$iso_file"
    else
        run_archiso -i "$iso_file"
    fi
}

# ============================================
# CLEAN
# ============================================

clean_all() {
    print_banner
    echo "[*] Limpiando..."
    rm -rf "$WORK_DIR"
    rm -rf "$OUTPUT_DIR"
    echo "[✓] Limpieza completada"
}

# ============================================
# MAIN
# ============================================

check_deps

case "${1:-}" in
    build)
        build_iso
        ;;
    build-fast)
        FAST_BUILD=true
        build_iso
        ;;
    release)
        build_iso
        bash "${SCRIPT_DIR}/scripts/release-iso.sh"
        ;;
    test)
        test_iso
        ;;
    clean)
        clean_all
        ;;
    *)
        print_banner
        echo "Uso:"
        echo "  sudo ./build-iso.sh build      # Compilar la ISO"
        echo "  sudo ./build-iso.sh build-fast # Compilar rápido (reutiliza work dir)"
        echo "  sudo ./build-iso.sh release    # Compilar y publicar en GitHub Releases"
        echo "  sudo ./build-iso.sh test       # Probar la última ISO en QEMU"
        echo "  sudo ./build-iso.sh clean      # Limpiar archivos temporales"
        echo ""
        ;;
esac
