#!/bin/bash
# Pi-Linux Installer v2.0
# Instalador automático e interactivo para Arch Linux con rices completos

set -e
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="$SCRIPT_DIR/modules"

# Explicit module execution order (avoids glob ASCII sort bug: 07 before 01)
MODULE_ORDER=(
    "00-preinstall.sh"
    "01-base.sh"
    "02-gpu.sh"
    "02-sddm.sh"
    "03-desktop.sh"
    "04-software.sh"
    "04-themes.sh"
    "05-software.sh"
    "06-hyprland-rice.sh"
    "07-keyd-remapper.sh"
    "08-download-organizer.sh"
)
LIB_DIR="$SCRIPT_DIR/lib"
VERSION="$(cat "${SCRIPT_DIR}/VERSION" 2>/dev/null || echo "2.0.0")"

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
    echo -e "  ${CYAN}4)${NC} Resetear historial de instalación"
    echo ""
    echo -e "  ${RED}0)${NC} Salir"
    echo ""
}

show_re_run_menu() {
    print_banner
    tracker_show_summary
    echo -e "${BOLD}¿Qué deseas hacer?${NC}"
    echo ""
    echo -e "  ${CYAN}1)${NC} Instalar software adicional (faltante)"
    echo -e "  ${CYAN}2)${NC} Ejecutar instalación completa de nuevo"
    echo -e "  ${CYAN}3)${NC} Ver resumen de instalación previa"
    echo ""
    echo -e "  ${RED}0)${NC} Salir"
    echo ""
}

# Software disponible para instalar adicionalmente
SOFTWARE_ITEMS=(
    "INSTALL_CHROME"      "Google Chrome"             "n"
    "INSTALL_BRAVE"       "Brave Browser"             "n"
    "INSTALL_FIREFOX"     "Firefox"                   "n"
    "INSTALL_VSCODE"      "Visual Studio Code"        "n"
    "INSTALL_OBSIDIAN"    "Obsidian"                  "n"
    "INSTALL_VLC"         "VLC"                       "n"
    "INSTALL_SPOTIFY"     "Spotify"                   "n"
    "INSTALL_OBS"         "OBS Studio"                "n"
    "INSTALL_KITTY"       "kitty terminal"            "n"
    "INSTALL_ALACRITTY"   "Alacritty terminal"        "n"
    "INSTALL_DOCKER"      "Docker"                    "n"
    "INSTALL_NODEJS"      "Node.js + npm + nvm"       "n"
    "INSTALL_PYTHON"      "Python completo"           "n"
    "INSTALL_FZF"         "fzf fuzzy finder"          "n"
    "INSTALL_RIPGREP"     "ripgrep"                   "n"
    "INSTALL_FD"          "fd find"                   "n"
    "INSTALL_BAT"         "bat (cat mejorado)"        "n"
    "INSTALL_EZA"         "eza (ls mejorado)"         "n"
    "INSTALL_ZOXIDE"      "zoxide (cd mejorado)"      "n"
    "INSTALL_ATUIN"       "Atuin (hist. shell)"       "n"
    "INSTALL_DELTA"       "git-delta"                 "n"
    "INSTALL_NEOVIM"      "Neovim"                    "n"
    "INSTALL_LAZYVIM"     "LazyVim (config Neovim)"   "n"
    "INSTALL_DOOMEMACS"   "Doom Emacs"                "n"
    "INSTALL_BTOP"        "btop monitor"              "n"
    "INSTALL_NVTOP"       "nvtop (GPU monitor)"       "n"
    "INSTALL_ZSH"         "Zsh"                       "n"
    "INSTALL_OHMYZSH"     "Oh-My-Zsh"                 "n"
    "INSTALL_FISH"        "Fish shell"                "n"
    "INSTALL_STARSHIP"    "Starship prompt"           "n"
    "INSTALL_TMUX"        "tmux"                      "n"
    "INSTALL_OHMYTMUX"    "Oh-My-Tmux"                "n"
)

select_addon_software() {
    echo ""
    echo -e "${BOLD}Selecciona el software adicional a instalar:${NC}"
    echo -e "${YELLOW}Escribe los números separados por espacios (ej: 1 3 5) o 'all' para todo${NC}"
    echo -e "${YELLOW}Deja vacío y pulsa Enter para cancelar${NC}"
    echo ""
    
    local i=1
    local idx=0
    local available_count=0
    while [[ $idx -lt ${#SOFTWARE_ITEMS[@]} ]]; do
        local var="${SOFTWARE_ITEMS[$idx]}"
        local name="${SOFTWARE_ITEMS[$((idx+1))]}"
        local default="${SOFTWARE_ITEMS[$((idx+2))]}"
        
        if ! tracker_is_installed "$var"; then
            printf "  ${CYAN}%2d)${NC} %-25s  ${GRAY}(no instalado)${NC}\n" "$i" "$name"
            available_count=$((available_count + 1))
        fi
        idx=$((idx + 3))
        i=$((i + 1))
    done
    
    if [[ $available_count -eq 0 ]]; then
        echo -e "${GREEN}¡Todo el software ya está instalado!${NC}"
        return 1
    fi
    
    echo ""
    read -rp "Selección: " selection
    
    if [[ -z "$selection" ]]; then
        return 1
    fi
    
    # Resetear todas las variables de instalación a "n"
    idx=0
    while [[ $idx -lt ${#SOFTWARE_ITEMS[@]} ]]; do
        local var="${SOFTWARE_ITEMS[$idx]}"
        declare -g "$var=n"
        idx=$((idx + 3))
    done
    
    if [[ "$selection" == "all" ]]; then
        idx=0
        while [[ $idx -lt ${#SOFTWARE_ITEMS[@]} ]]; do
            local var="${SOFTWARE_ITEMS[$idx]}"
            if ! tracker_is_installed "$var"; then
                declare -g "$var=y"
            fi
            idx=$((idx + 3))
        done
    else
        for num in $selection; do
            if [[ "$num" =~ ^[0-9]+$ ]]; then
                local target_idx=$(( (num - 1) * 3 ))
                if [[ $target_idx -lt ${#SOFTWARE_ITEMS[@]} ]]; then
                    local var="${SOFTWARE_ITEMS[$target_idx]}"
                    declare -g "$var=y"
                fi
            fi
        done
    fi
    
    return 0
}

run_addon_modules() {
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}Instalando software adicional...${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    for module in "$MODULES_DIR"/04-software.sh "$MODULES_DIR"/05-software.sh; do
        if [[ -f "$module" ]]; then
            local basename_module
            basename_module=$(basename "$module")
            echo ""
            echo -e "${CYAN}▶ Ejecutando: $basename_module${NC}"
            bash "$module"
            echo -e "${GREEN}✓ Completado: $basename_module${NC}"
        fi
    done
    
    echo ""
    echo -e "${GREEN}✓ Software adicional instalado!${NC}"
}

select_username() {
    echo ""
    echo -e "${BOLD}Configuración del Usuario:${NC}"
    echo ""
    
    # Sugerir el usuario actual (quien ejecutó sudo) o el de config
    local suggested="${USERNAME:-${SUDO_USER:-user}}"
    read -rp "Nombre de usuario [$suggested]: " input_user
    
    if [[ -n "$input_user" ]]; then
        USERNAME="$input_user"
    else
        USERNAME="$suggested"
    fi
    
    # Validate username (POSIX compliant: a-z, 0-9, _, -, cannot start with - or digit)
    if ! [[ "$USERNAME" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
        error "Nombre de usuario inválido: '$USERNAME'. Solo minúsculas, números, guiones y guiones bajos. Debe empezar con letra o guión bajo."
        return 1
    fi
    
    export USERNAME
    
    # Verificar que el usuario existe en el sistema
    if ! id "$USERNAME" &>/dev/null; then
        warning "El usuario '$USERNAME' no existe en el sistema."
        read -rp "¿Crear usuario '$USERNAME' ahora? [S/n]: " create_user
        if [[ "$create_user" != "n" && "$create_user" != "N" ]]; then
            info "Creando usuario '$USERNAME'..."
            useradd -m -G wheel,audio,video,storage,optical,network -s /bin/bash "$USERNAME" 2>/dev/null || \
            useradd -m -G users,audio,video,storage -s /bin/bash "$USERNAME"
            
            echo ""
            echo -e "${YELLOW}⚠  Establece una contraseña para $USERNAME:${NC}"
            passwd "$USERNAME"
            
            # Asegurar que wheel tenga sudo
            if [[ ! -f /etc/sudoers.d/10-pi-linux ]]; then
                echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/10-pi-linux
                chmod 440 /etc/sudoers.d/10-pi-linux
            fi
            
            success "Usuario '$USERNAME' creado"
        else
            warning "Continuando sin crear usuario. Algunos módulos pueden fallar."
        fi
    else
        success "Usuario: $USERNAME"
    fi
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
        
        # Parsear de forma segura (evita source arbitrario)
        local var val
        while IFS='=' read -r var val; do
            # Saltar líneas vacías o comentarios
            [[ -z "$var" || "$var" =~ ^[[:space:]]*# ]] && continue
            # Solo permitir variables con nombres seguros
            [[ "$var" =~ ^[A-Z_][A-Z0-9_]*$ ]] || continue
            # Quitar comillas del valor
            val="${val#\"}"; val="${val%\"}"
            val="${val#\'}"; val="${val%\'}"
            case "$var" in
                DESKTOP_ENV|THEME|RICE_TYPE|HYPR_RICE|GNOME_RICE|PLASMA_RICE|GPU_TYPE|SDDM_THEME|USERNAME|HOSTNAME|TIMEZONE|LOCALE|KEYMAP|INSTALL_*)
                    declare -g "$var=$val"
                    ;;
            esac
        done < <(grep -E '^[A-Z_][A-Z0-9_]*=' "$conf")
        
        # Mapear variables de rice del conf a las del instalador
        case "${DESKTOP_ENV:-plasma}" in
            plasma)
                RICE_TYPE="${PLASMA_RICE:-${THEME:-sweet}}"
                ;;
            gnome)
                RICE_TYPE="${GNOME_RICE:-${THEME:-sweet}}"
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
    echo "  Usuario: ${PI_REAL_USER:-$USERNAME}"
    echo "  DE:      $DESKTOP_ENV"
    echo "  Rice:    ${RICE_TYPE:-none}"
    echo "  GPU:     $GPU_TYPE"
    echo "  SDDM:    sddm-astronaut-theme (unificado)"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  ⏱️  Tiempo estimado: 20-40 minutos"
    echo "  💾 Espacio en disco: ~8 GB"
    echo "  🌐 Descarga estimada: ~4-6 GB"
}

# ============================================
# EJECUCIÓN DE MÓDULOS
# ============================================

run_modules() {
    local total=${#MODULE_ORDER[@]}
    local current=1
    
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}Iniciando instalación (${total} módulos)...${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    for module_name in "${MODULE_ORDER[@]}"; do
        local module="$MODULES_DIR/$module_name"
        if [[ -f "$module" ]]; then
            local basename_module
            basename_module=$(basename "$module")
            
            if [[ "$basename_module" == "06-dotfiles.sh" ]]; then
                info "Ignorando módulo antiguo: $basename_module"
                continue
            fi
            
            echo ""
            echo -e "${CYAN}[${current}/${total}] Ejecutando: $basename_module${NC}"
            if bash "$module"; then
                echo -e "${GREEN}✓ Completado: $basename_module${NC}"
            else
                echo -e "${RED}✗ Falló: $basename_module${NC}"
                if [[ "$FORCE_YES" != true ]]; then
                    read -rp "¿Continuar con el siguiente módulo? [S/n]: " cont
                    [[ "$cont" == "n" || "$cont" == "N" ]] && break
                fi
            fi
            ((current++))
        else
            warning "Módulo no encontrado: $module_name"
        fi
    done
}

# ============================================
# MAIN
# ============================================

main() {
    FORCE_YES=false
    for arg in "$@"; do
        case "$arg" in
            --yes) FORCE_YES=true ;;
        esac
    done
    export FORCE_YES
    
    check_root
    check_arch
    
    print_banner
    check_connection
    
    # Verificar si hay argumento --unattended en cualquier posición
    local has_unattended=false
    for arg in "$@"; do
        if [[ "$arg" == "--unattended" ]]; then
            has_unattended=true
            break
        fi
    done
    if [[ "$has_unattended" == true ]]; then
        info "Modo desatendido activado"
        # In unattended mode, never prompt interactively
        FORCE_YES=true
        load_unattended_config
        
        # Asegurar que el usuario del config existe
        if [[ -n "${USERNAME:-}" ]] && ! id "$USERNAME" &>/dev/null; then
            warning "El usuario '$USERNAME' no existe. Creándolo..."
            useradd -m -G wheel,audio,video,storage,optical,network -s /bin/bash "$USERNAME" 2>/dev/null || \
            useradd -m -G users,audio,video,storage -s /bin/bash "$USERNAME"
            local user_pass="${USER_PASSWORD:-$USERNAME}"
            echo "${USERNAME}:${user_pass}" | chpasswd
            info "Usuario '$USERNAME' creado con contraseña: $user_pass"
        fi
        
        # Librería ya cargada al inicio
        
        show_summary
        if [[ "$FORCE_YES" == true ]]; then
            confirm="y"
        else
            read -rp "¿Iniciar instalación desatendida? [S/n]: " confirm
        fi
        [[ "$confirm" == "n" || "$confirm" == "N" ]] && exit 0
        run_modules
        tracker_save_installation
    else
        # Detectar si ya se ejecutó anteriormente
        if tracker_was_run; then
            show_re_run_menu
            read -rp "Selecciona [0-4]: " re_choice
            
            case $re_choice in
                1)
                    info "Modo software adicional"
                    if select_addon_software; then
                        # Librería ya cargada al inicio
                        run_addon_modules
                        tracker_save_installation
                        echo ""
                        echo -e "${GREEN}✓ Software adicional instalado correctamente.${NC}"
                        exit 0
                    else
                        info "Cancelado. Saliendo..."
                        exit 0
                    fi
                    ;;
                2)
                    info "Re-ejecutando instalación completa..."
                    ;;
                3)
                    tracker_show_summary
                    echo ""
                    read -rp "Pulsa Enter para continuar..."
                    main "$@"
                    return
                    ;;
                4)
                    echo ""
                    read -rp "¿Borrar el historial de instalación previa? [s/N]: " confirm_reset
                    if [[ "$confirm_reset" == "s" || "$confirm_reset" == "S" ]]; then
                        rm -f "$PI_TRACKER_FILE"
                        success "Historial de instalación borrado. La próxima ejecución será como la primera vez."
                    else
                        info "Cancelado."
                    fi
                    echo ""
                    read -rp "Pulsa Enter para continuar..."
                    main "$@"
                    return
                    ;;
                0)
                    exit 0
                    ;;
            esac
        fi
        
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
                select_username
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
        
        # En modo automático/express, preguntar usuario si no está definido
        if [[ -z "${USERNAME:-}" ]]; then
            select_username
        fi
        
        # Librería ya cargada al inicio
        
        show_summary
        if [[ "$FORCE_YES" == true ]]; then
            confirm="y"
        else
            read -rp "¿Iniciar instalación? [S/n]: " confirm
        fi
        [[ "$confirm" == "n" || "$confirm" == "N" ]] && exit 0
        
        run_modules
        tracker_save_installation
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
    if [[ "$FORCE_YES" == true ]]; then
        reboot_now="n"
    else
        read -rp "¿Reiniciar ahora? [s/N]: " reboot_now
    fi
    [[ "$reboot_now" == "s" || "$reboot_now" == "S" ]] && reboot
}

main "$@"
