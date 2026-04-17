#!/bin/bash
# Pi-Linux Installer v2.0
# Instalador automático e interactivo para Arch Linux con rices completos

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="$SCRIPT_DIR/modules"
LIB_DIR="$SCRIPT_DIR/lib"
VERSION="2.0.0"

# Cargar librería común
source "${LIB_DIR}/pi-linux-common.sh"

# ============================================
# BANNER
# ============================================

print_banner() {
    clear
    echo -e "${MAGENTA}"
    echo "    ____  _       __    _           __  _"
    echo "   / __ \\(_)___ _/ /_  (_)_________/ /_(_)___  ___"
    echo "  / /_/ / / __ '/ __ \\/ / ___/ ___/ __/ / __ \\/ _ \\"
    echo " / ____/ / /_/ / / / / (__  |__  ) /_/ / / / /  __/"
    echo "/_/   /_/\\__, /_/ /_/_/____/____/\\__/_/_/ /_/\\___/"
    echo "        /____/"
    echo -e "${NC}"
    echo -e "${CYAN}    Instalador Automático para Arch Linux v${VERSION}${NC}"
    echo -e "${CYAN}    Con rices automáticos: HyDE · WhiteSur · Sweet · Catppuccin${NC}"
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# ============================================
# VALIDACIONES
# ============================================

check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "Este script debe ejecutarse como root (sudo)"
        exit 1
    fi
}

check_arch() {
    if [[ ! -f /etc/arch-release ]]; then
        error "Este instalador solo funciona en Arch Linux"
        exit 1
    fi
}

check_connection() {
    info "Verificando conexión..."
    if ! ping -c 1 archlinux.org &>/dev/null; then
        error "No hay conexión a internet"
        exit 1
    fi
    success "Conexión OK"
}

# ============================================
# MENÚS INTERACTIVOS
# ============================================

show_menu() {
    print_banner
    echo -e "${BOLD}Modo de Instalación:${NC}"
    echo ""
    echo -e "  ${CYAN}1)${NC} Modo Automático (KDE Plasma + Sweet)"
    echo -e "  ${CYAN}2)${NC} Modo Interactivo Avanzado (Elige DE + Rice + GPU)"
    echo -e "  ${CYAN}3)${NC} Modo Rice Express (Hyprland HyDE / GNOME WhiteSur / Plasma Sweet)"
    echo ""
    echo -e "  ${RED}0)${NC} Salir"
    echo ""
}

select_desktop_environment() {
    echo ""
    echo -e "${BOLD}Selecciona el Entorno de Escritorio:${NC}"
    echo ""
    echo -e "  ${CYAN}1)${NC} KDE Plasma 6 - Moderno y customizable"
    echo -e "  ${CYAN}2)${NC} GNOME 46/47 - Limpio y minimalista"
    echo -e "  ${CYAN}3)${NC} Hyprland - Tiling Wayland compositor"
    echo ""
    read -rp "Selecciona [1-3]: " de_choice
    case $de_choice in
        1) DESKTOP_ENV="plasma" ;;
        2) DESKTOP_ENV="gnome" ;;
        3) DESKTOP_ENV="hyprland" ;;
        *) DESKTOP_ENV="plasma" ;;
    esac
    export DESKTOP_ENV
    success "DE seleccionado: $DESKTOP_ENV"
}

select_rice() {
    echo ""
    echo -e "${BOLD}Selecciona el Rice (Tema Completo):${NC}"
    echo ""
    
    case "$DESKTOP_ENV" in
        plasma)
            echo -e "  ${CYAN}1)${NC} Sweet        - Moderno oscuro con acentos rosas"
            echo -e "  ${CYAN}2)${NC} WhiteSur     - Estilo macOS completo"
            echo -e "  ${CYAN}3)${NC} MacTahoe     - macOS Tahoe más reciente"
            echo -e "  ${CYAN}4)${NC} Layan        - Material Design púrpura"
            echo -e "  ${CYAN}5)${NC} Catppuccin   - Pastel suave (Mocha)"
            echo -e "  ${CYAN}6)${NC} Orchis       - Material redondeado"
            echo -e "  ${CYAN}0)${NC} Ninguno      - Solo el DE sin temas"
            echo ""
            read -rp "Selecciona [0-6]: " rice_choice
            case $rice_choice in
                1) RICE_TYPE="sweet" ;;
                2) RICE_TYPE="whitesur" ;;
                3) RICE_TYPE="mactahoe" ;;
                4) RICE_TYPE="layan" ;;
                5) RICE_TYPE="catppuccin" ;;
                6) RICE_TYPE="orchis" ;;
                *) RICE_TYPE="none" ;;
            esac
            ;;
            
        gnome)
            echo -e "  ${CYAN}1)${NC} WhiteSur     - Estilo macOS completo (GTK + Shell + Icons)"
            echo -e "  ${CYAN}2)${NC} Orchis       - Material Design elegante"
            echo -e "  ${CYAN}3)${NC} Graphite     - Flat minimalista oscuro"
            echo -e "  ${CYAN}4)${NC} Catppuccin   - Pastel para developers"
            echo -e "  ${CYAN}5)${NC} Nordic       - Paleta Nord azul"
            echo -e "  ${CYAN}0)${NC} Ninguno      - Solo el DE sin temas"
            echo ""
            read -rp "Selecciona [0-5]: " rice_choice
            case $rice_choice in
                1) RICE_TYPE="whitesur" ;;
                2) RICE_TYPE="orchis" ;;
                3) RICE_TYPE="graphite" ;;
                4) RICE_TYPE="catppuccin" ;;
                5) RICE_TYPE="nordic" ;;
                *) RICE_TYPE="none" ;;
            esac
            ;;
            
        hyprland)
            echo -e "  ${CYAN}1)${NC} HyDE         - Recomendado oficial por Hyprland (9k⭐)"
            echo -e "  ${CYAN}2)${NC} ML4W         - My Linux For Work (amigable principiantes)"
            echo -e "  ${CYAN}3)${NC} end-4        - Illogical Impulse (visualmente impresionante)"
            echo -e "  ${CYAN}0)${NC} Ninguno      - Config mínima fallback"
            echo ""
            read -rp "Selecciona [0-3]: " rice_choice
            case $rice_choice in
                1) HYPR_RICE="hyde" ;;
                2) HYPR_RICE="ml4w" ;;
                3) HYPR_RICE="end4" ;;
                *) HYPR_RICE="none" ;;
            esac
            export HYPR_RICE
            RICE_TYPE="$HYPR_RICE"
            ;;
            
        *)
            RICE_TYPE="none"
            ;;
    esac
    
    export RICE_TYPE
    export THEME="$RICE_TYPE"
    
    if [[ "$RICE_TYPE" == "none" ]]; then
        info "Rice: Ninguno (DE puro)"
    else
        success "Rice seleccionado: $RICE_TYPE"
    fi
}

select_gpu() {
    echo ""
    echo -e "${BOLD}Detección GPU:${NC}"
    if lspci | grep -i nvidia &>/dev/null; then
        GPU_TYPE="nvidia"
        echo "Detectada: NVIDIA"
    elif lspci | grep -i amd &>/dev/null; then
        GPU_TYPE="amd"
        echo "Detectada: AMD"
    elif lspci | grep -i intel &>/dev/null; then
        GPU_TYPE="intel"
        echo "Detectada: Intel"
    else
        GPU_TYPE="generic"
        echo "GPU genérica"
    fi
    export GPU_TYPE
}

show_rice_express_menu() {
    echo ""
    echo -e "${BOLD}Rice Express — Configuraciones pre-optimizadas:${NC}"
    echo ""
    echo -e "  ${CYAN}1)${NC} 🏴‍☠️ Hyprland + HyDE       - Tiling moderno, recomendado"
    echo -e "  ${CYAN}2)${NC} 🍎 GNOME + WhiteSur      - macOS-like completo"
    echo -e "  ${CYAN}3)${NC} 💜 Plasma + Sweet         - Moderno oscuro y elegante"
    echo -e "  ${CYAN}4)${NC} 🌌 Plasma + Catppuccin    - Pastel developer-friendly"
    echo ""
    read -rp "Selecciona [1-4]: " express_choice
    
    case $express_choice in
        1)
            DESKTOP_ENV="hyprland"
            HYPR_RICE="hyde"
            GPU_TYPE="auto"
            RICE_TYPE="hyde"
            ;;
        2)
            DESKTOP_ENV="gnome"
            RICE_TYPE="whitesur"
            GPU_TYPE="auto"
            INSTALL_GNOME_EXTENSIONS="y"
            ;;
        3)
            DESKTOP_ENV="plasma"
            RICE_TYPE="sweet"
            GPU_TYPE="auto"
            ;;
        4)
            DESKTOP_ENV="plasma"
            RICE_TYPE="catppuccin"
            GPU_TYPE="auto"
            ;;
        *)
            DESKTOP_ENV="plasma"
            RICE_TYPE="sweet"
            GPU_TYPE="auto"
            ;;
    esac
    
    export DESKTOP_ENV HYPR_RICE RICE_TYPE THEME GPU_TYPE INSTALL_GNOME_EXTENSIONS
}

# ============================================
# MODO DESATENDIDO
# ============================================

load_unattended_config() {
    local conf="$SCRIPT_DIR/config/unattended.conf"
    if [[ -f "$conf" ]]; then
        info "Cargando configuración desatendida..."
        source "$conf"
        
        # Mapear variables de rice del conf a las del instalador
        case "${DESKTOP_ENV}" in
            plasma)
                RICE_TYPE="${PLASMA_RICE:-$THEME}"
                ;;
            gnome)
                RICE_TYPE="${GNOME_RICE:-$THEME}"
                ;;
            hyprland)
                HYPR_RICE="${HYPR_RICE:-hyde}"
                RICE_TYPE="$HYPR_RICE"
                ;;
        esac
        
        THEME="$RICE_TYPE"
        export RICE_TYPE THEME HYPR_RICE INSTALL_GNOME_EXTENSIONS
        success "Configuración cargada"
    else
        warning "No se encontró unattended.conf, usando defaults"
        DESKTOP_ENV="plasma"
        RICE_TYPE="sweet"
        THEME="sweet"
        GPU_TYPE="auto"
        export DESKTOP_ENV RICE_TYPE THEME GPU_TYPE
    fi
}

# ============================================
# RESUMEN Y CONFIRMACIÓN
# ============================================

show_summary() {
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}Resumen de Instalación:${NC}"
    echo "  DE:     $DESKTOP_ENV"
    echo "  Rice:   ${RICE_TYPE:-none}"
    echo "  GPU:    $GPU_TYPE"
    echo "  SDDM:   sddm-astronaut-theme (unificado)"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# ============================================
# EJECUCIÓN DE MÓDULOS
# ============================================

run_modules() {
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}Iniciando instalación...${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Los módulos se ejecutan en orden numérico
    # 00: preinstall
    # 01: base
    # 02: sddm (nuevo)
    # 02: gpu (renombrado lógicamente, sigue siendo 02-gpu.sh)
    # 03: desktop
    # 04: themes (rice completo)
    # 04: software (adicional)
    # 05: software (más software)
    # 06: hyprland-rice (nuevo)
    
    for module in "$MODULES_DIR"/*.sh; do
        if [[ -f "$module" ]]; then
            local basename_module
            basename_module=$(basename "$module")
            
            # Saltar el módulo de dotfiles antiguo si existe
            if [[ "$basename_module" == "06-dotfiles.sh" ]]; then
                info "Ignorando módulo antiguo: $basename_module"
                continue
            fi
            
            echo ""
            echo -e "${CYAN}▶ Ejecutando: $basename_module${NC}"
            bash "$module"
            echo -e "${GREEN}✓ Completado: $basename_module${NC}"
        fi
    done
}

# ============================================
# MAIN
# ============================================

main() {
    check_root
    check_arch
    
    print_banner
    check_connection
    
    # Verificar si hay argumento --unattended
    if [[ "${1:-}" == "--unattended" ]]; then
        info "Modo desatendido activado"
        load_unattended_config
        show_summary
        read -rp "¿Iniciar instalación desatendida? [S/n]: " confirm
        [[ "$confirm" == "n" || "$confirm" == "N" ]] && exit 0
        run_modules
    else
        show_menu
        read -rp "Selecciona [0-3]: " choice
        
        case $choice in
            1)
                info "Modo automático (KDE Plasma + Sweet)"
                DESKTOP_ENV="plasma"
                RICE_TYPE="sweet"
                THEME="sweet"
                GPU_TYPE="auto"
                export DESKTOP_ENV RICE_TYPE THEME GPU_TYPE
                ;;
            2)
                select_desktop_environment
                select_rice
                select_gpu
                ;;
            3)
                show_rice_express_menu
                ;;
            0)
                exit 0
                ;;
        esac
        
        show_summary
        read -rp "¿Iniciar instalación? [S/n]: " confirm
        [[ "$confirm" == "n" || "$confirm" == "N" ]] && exit 0
        
        run_modules
    fi
    
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✓ Instalación completada!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${CYAN}Próximos pasos:${NC}"
    echo "  1. Revisa que todo esté correcto"
    echo "  2. Reinicia el sistema"
    echo ""
    read -rp "¿Reiniciar ahora? [s/N]: " reboot_now
    [[ "$reboot_now" == "s" || "$reboot_now" == "S" ]] && reboot
}

main "$@"
