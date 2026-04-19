#!/bin/bash
# Pi-Linux TUI Installer
# Interfaz de usuario en modo texto con whiptail/dialog

set -e
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PI_LINUX="${SCRIPT_DIR}/pi-linux.sh"

# Cargar librería común si existe (para tracker en modo re-run)
if [[ -f "${SCRIPT_DIR}/lib/pi-linux-common.sh" ]]; then
    source "${SCRIPT_DIR}/lib/pi-linux-common.sh"
fi

# Detectar si tenemos whiptail o dialog
if command -v whiptail &>/dev/null; then
    TUI="whiptail"
    ARGS=""
elif command -v dialog &>/dev/null; then
    TUI="dialog"
    ARGS="--stdout"
else
    echo "Instalando whiptail..."
    pacman -S --needed --noconfirm libnewt 2>/dev/null || pacman -S --needed --noconfirm dialog
    TUI="whiptail"
    ARGS=""
fi

if [[ -z "$TUI" ]]; then
    echo "No se encontró whiptail ni dialog. Usando modo texto..."
    exec "${SCRIPT_DIR}/pi-linux.sh" "$@"
fi

# ============================================
# DIMENSIONES
# ============================================

H=20
W=70
LIST_H=12

# ============================================
# FUNCIONES TUI
# ============================================

tui_msg() {
    local title="$1"
    local msg="$2"
    $TUI $ARGS --title "Pi-Linux Installer" --msgbox "$msg" $H $W
}

tui_yesno() {
    local title="$1"
    local msg="$2"
    $TUI $ARGS --title "$title" --yesno "$msg" $H $W
}

tui_menu() {
    local title="$1"
    local msg="$2"
    shift 2
    $TUI $ARGS --title "$title" --menu "$msg" $H $W $LIST_H "$@"
}

tui_checklist() {
    local title="$1"
    local msg="$2"
    shift 2
    $TUI $ARGS --title "$title" --checklist "$msg" $((H + 6)) $W $LIST_H "$@"
}

tui_radiolist() {
    local title="$1"
    local msg="$2"
    shift 2
    $TUI $ARGS --title "$title" --radiolist "$msg" $((H + 4)) $W $LIST_H "$@"
}

# ============================================
# PASOS DEL INSTALADOR
# ============================================

step_welcome() {
    tui_msg "Bienvenido" "
🥧  Pi-Linux Installer v2.0

Este asistente te guiará por la instalación
de Arch Linux con rices completos.

Incluye:
  • Hyprland + HyDE
  • GNOME + WhiteSur/Orchis
  • Plasma 6 + Sweet/Catppuccin
  • SDDM tematizado
  • Software productivo

Pulsa OK para continuar."
}

step_username() {
    local user_input
    user_input=$($TUI $ARGS --title "Usuario del Sistema" --inputbox "
Introduce el nombre de usuario para el sistema.
Este usuario recibirá los dotfiles y configuraciones.

Si el usuario no existe, se creará automáticamente." $((H + 4)) $W "${SUDO_USER:-user}")
    
    if [[ -z "$user_input" ]]; then
        user_input="${SUDO_USER:-user}"
    fi
    
    USERNAME="$user_input"
    export USERNAME
    
    # Verificar si existe
    if ! id "$USERNAME" &>/dev/null; then
        if tui_yesno "Crear Usuario" "El usuario '$USERNAME' no existe en el sistema.\n\n¿Deseas crearlo ahora?"; then
            useradd -m -G wheel,audio,video,storage,optical,network -s /bin/bash "$USERNAME" 2>/dev/null || \
            useradd -m -G users,audio,video,storage -s /bin/bash "$USERNAME"
            
            # Establecer contraseña realmente
            local pass1 pass2
            while true; do
                pass1=$($TUI $ARGS --title "Contraseña" --passwordbox "Establece una contraseña para $USERNAME:" $H $W 3>&1 1>&2 2>&3)
                pass2=$($TUI $ARGS --title "Confirmar" --passwordbox "Confirma la contraseña:" $H $W 3>&1 1>&2 2>&3)
                if [[ "$pass1" == "$pass2" && -n "$pass1" ]]; then
                    echo "$USERNAME:$pass1" | chpasswd
                    break
                else
                    tui_msg "Error" "Las contraseñas no coinciden o están vacías. Intenta de nuevo."
                fi
            done
            
            if [[ ! -f /etc/sudoers.d/10-pi-linux ]]; then
                echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/10-pi-linux
                chmod 440 /etc/sudoers.d/10-pi-linux
            fi
        fi
    fi
}

step_mode() {
    local mode
    mode=$(tui_menu "Modo de Instalación" "Elige cómo quieres instalar:" \
        "auto"      "Automático (KDE Plasma + Sweet)" \
        "express"   "Rice Express (presets pre-optimizados)" \
        "advanced"  "Avanzado (elige DE, rice y GPU)" \
        "unattended" "Desatendido (usa config/unattended.conf)")
    echo "$mode"
}

step_express() {
    local choice
    choice=$(tui_menu "Rice Express" "Selecciona un preset:" \
        "hyprland-hyde"    "🏴‍☠️ Hyprland + HyDE (recomendado)" \
        "gnome-whitesur"   "🍎 GNOME + WhiteSur (macOS-like)" \
        "plasma-sweet"     "💜 Plasma + Sweet (moderno oscuro)" \
        "plasma-catppuccin" "🌌 Plasma + Catppuccin (pastel dev)")
    echo "$choice"
}

step_desktop_env() {
    local de
    de=$(tui_menu "Entorno de Escritorio" "Selecciona tu DE:" \
        "plasma"   "KDE Plasma 6 — Moderno y customizable" \
        "gnome"    "GNOME 46/47 — Limpio y minimalista" \
        "hyprland" "Hyprland — Tiling Wayland compositor")
    echo "$de"
}

step_rice_plasma() {
    local rice
    rice=$(tui_menu "Rice para Plasma" "Selecciona el tema completo:" \
        "sweet"       "Sweet — Oscuro con acentos rosas" \
        "whitesur"    "WhiteSur — macOS completo" \
        "mactahoe"    "MacTahoe — macOS Tahoe reciente" \
        "layan"       "Layan — Material púrpura" \
        "catppuccin"  "Catppuccin — Pastel Mocha" \
        "orchis"      "Orchis — Material redondeado" \
        "none"        "Ninguno — DE puro")
    echo "$rice"
}

step_rice_gnome() {
    local rice
    rice=$(tui_menu "Rice para GNOME" "Selecciona el tema completo:" \
        "whitesur"    "WhiteSur — macOS completo" \
        "orchis"      "Orchis — Material elegante" \
        "graphite"    "Graphite — Minimalista oscuro" \
        "catppuccin"  "Catppuccin — Pastel dev" \
        "nordic"      "Nordic — Paleta Nord azul" \
        "none"        "Ninguno — DE puro")
    echo "$rice"
}

step_rice_hyprland() {
    local rice
    rice=$(tui_menu "Rice para Hyprland" "Selecciona el dotfiles:" \
        "hyde"   "HyDE — Recomendado oficial (9k⭐)" \
        "ml4w"   "ML4W — Amigable principiantes" \
        "end4"   "end-4 — Visualmente impresionante" \
        "none"   "Ninguno — Config mínima fallback")
    echo "$rice"
}

step_gpu() {
    local gpu
    gpu=$(tui_menu "Configuración GPU" "Selecciona tu GPU:" \
        "auto"   "Detección automática" \
        "nvidia" "NVIDIA (drivers propietarios)" \
        "amd"    "AMD Radeon (open source)" \
        "intel"  "Intel Graphics (open source)" \
        "vm"     "Máquina virtual" \
        "generic" "Genérica / Desconocida")
    echo "$gpu"
}

step_software() {
    local sel
    sel=$(tui_checklist "Software Adicional" "Selecciona con ESPACIO:" \
        "chrome"    "Google Chrome" OFF \
        "brave"     "Brave Browser" OFF \
        "firefox"   "Firefox" ON \
        "vscode"    "Visual Studio Code" ON \
        "spotify"   "Spotify" OFF \
        "docker"    "Docker" ON \
        "nvim"      "Neovim" ON \
        "zsh"       "Zsh + Oh-My-Zsh" ON \
        "tmux"      "tmux" ON \
        "fzf"       "fzf fuzzy finder" ON \
        "btop"      "btop monitor" ON \
        "starship"  "Starship prompt" ON)
    echo "$sel"
}

step_confirm() {
    local de="$1"
    local rice="$2"
    local gpu="$3"
    local user="${USERNAME:-${SUDO_USER:-user}}"
    
    if tui_yesno "Confirmación" "
Resumen de la instalación:

  Usuario: $user
  DE:      $de
  Rice:    $rice
  GPU:     $gpu
  SDDM:    sddm-astronaut-theme

  ⏱️  Tiempo estimado: 20-40 minutos
  💾 Espacio en disco: ~8 GB
  🌐 Descarga estimada: ~4-6 GB

¿Iniciar instalación?"; then
        return 0
    else
        return 1
    fi
}

step_running() {
    local de="$1"
    local rice="$2"
    local gpu="$3"
    
    export DESKTOP_ENV="$de"
    export RICE_TYPE="$rice"
    export THEME="$rice"
    export GPU_TYPE="$gpu"
    export HYPR_RICE="$rice"
    
    local logfile="/tmp/pi-linux-install.log"
    > "$logfile"
    
    (
        bash "$PI_LINUX" --unattended >> "$logfile" 2>&1
    ) &
    local pid=$!
    
    {
        while kill -0 $pid 2>/dev/null; do
            local lastline
            lastline=$(tail -n 1 "$logfile" 2>/dev/null | cut -c1-60)
            echo -e "XXX\n0\nInstalando Pi-Linux:\n  DE:   $de\n  Rice: $rice\n\n$lastline\nXXX"
            sleep 2
        done
    } | $TUI $ARGS --title "Instalando Pi-Linux" --gauge "\nIniciando instalación..." $((H + 6)) $W 0
    
    wait $pid
    local exit_code=$?
    
    if [[ $exit_code -ne 0 ]]; then
        tui_msg "Error de Instalación" "La instalación falló (código $exit_code).\n\nLog: $logfile"
        return 1
    fi
    return 0
}

# ============================================
# MODO RE-RUN (Software Adicional)
# ============================================

step_welcome_rerun() {
    local date_prev user_prev de_prev
    date_prev=$(tracker_get_var "INSTALL_DATE" "desconocida")
    user_prev=$(tracker_get_var "USERNAME" "desconocido")
    de_prev=$(tracker_get_var "DESKTOP_ENV" "-")
    
    tui_msg "Instalación Detectada" "
🥧  Pi-Linux Installer v2.0

Se detectó una instalación previa:
  Fecha:    $date_prev
  Usuario:  $user_prev
  DE:       $de_prev

Puedes instalar software adicional
que no se incluyó en la instalación
original, o ejecutar todo de nuevo."
}

step_rerun_menu() {
    local choice
    choice=$(tui_menu "¿Qué deseas hacer?" "Elige una opción:" \
        "addon"     "Instalar software adicional (faltante)" \
        "full"      "Ejecutar instalación completa de nuevo" \
        "summary"   "Ver resumen de instalación previa" \
        "reset"     "Resetear historial de instalación")
    echo "$choice"
}

step_addon() {
    # Lista de software con sus tags para whiptail
    # tag descripción variable
    local -a items=(
        "chrome"      "Google Chrome"             "INSTALL_CHROME"
        "brave"       "Brave Browser"             "INSTALL_BRAVE"
        "firefox"     "Firefox"                   "INSTALL_FIREFOX"
        "vscode"      "Visual Studio Code"        "INSTALL_VSCODE"
        "obsidian"    "Obsidian"                  "INSTALL_OBSIDIAN"
        "vlc"         "VLC"                       "INSTALL_VLC"
        "spotify"     "Spotify"                   "INSTALL_SPOTIFY"
        "obs"         "OBS Studio"                "INSTALL_OBS"
        "kitty"       "kitty terminal"            "INSTALL_KITTY"
        "alacritty"   "Alacritty terminal"        "INSTALL_ALACRITTY"
        "docker"      "Docker"                    "INSTALL_DOCKER"
        "nodejs"      "Node.js + npm + nvm"       "INSTALL_NODEJS"
        "python"      "Python completo"           "INSTALL_PYTHON"
        "fzf"         "fzf fuzzy finder"          "INSTALL_FZF"
        "ripgrep"     "ripgrep"                   "INSTALL_RIPGREP"
        "fd"          "fd find"                   "INSTALL_FD"
        "bat"         "bat (cat mejorado)"        "INSTALL_BAT"
        "eza"         "eza (ls mejorado)"         "INSTALL_EZA"
        "zoxide"      "zoxide (cd mejorado)"      "INSTALL_ZOXIDE"
        "atuin"       "Atuin (hist. shell)"       "INSTALL_ATUIN"
        "delta"       "git-delta"                 "INSTALL_DELTA"
        "neovim"      "Neovim"                    "INSTALL_NEOVIM"
        "lazyvim"     "LazyVim (config Neovim)"   "INSTALL_LAZYVIM"
        "doomemacs"   "Doom Emacs"                "INSTALL_DOOMEMACS"
        "btop"        "btop monitor"              "INSTALL_BTOP"
        "nvtop"       "nvtop (GPU monitor)"       "INSTALL_NVTOP"
        "zsh"         "Zsh"                       "INSTALL_ZSH"
        "ohmyzsh"     "Oh-My-Zsh"                 "INSTALL_OHMYZSH"
        "fish"        "Fish shell"                "INSTALL_FISH"
        "starship"    "Starship prompt"           "INSTALL_STARSHIP"
        "tmux"        "tmux"                      "INSTALL_TMUX"
        "ohmytmux"    "Oh-My-Tmux"                "INSTALL_OHMYTMUX"
    )
    
    # Construir argumentos para whiptail solo con lo no instalado
    local whiptail_args=()
    local total_items=0
    local i=0
    while [[ $i -lt ${#items[@]} ]]; do
        local tag="${items[$i]}"
        local desc="${items[$((i+1))]}"
        local var="${items[$((i+2))]}"
        
        if ! tracker_is_installed "$var"; then
            whiptail_args+=("$tag" "$desc" "OFF")
            total_items=$((total_items + 1))
        fi
        i=$((i + 3))
    done
    
    if [[ $total_items -eq 0 ]]; then
        tui_msg "Todo Instalado" "
✅ ¡Todo el software disponible ya está instalado!

No hay nada adicional que instalar."
        return 1
    fi
    
    local sel
    sel=$($TUI $ARGS --title "Software Adicional" --checklist "
Selecciona el software que deseas instalar.
Usa ESPACIO para marcar/desmarcar.
Solo se muestra lo NO instalado:" $((H + 10)) $W $((LIST_H + 6)) "${whiptail_args[@]}")
    
    if [[ -z "$sel" ]]; then
        return 1
    fi
    
    # Resetear todas las variables a "n"
    i=0
    while [[ $i -lt ${#items[@]} ]]; do
        local var="${items[$((i+2))]}"
        declare -gx "$var=n"
        i=$((i + 3))
    done
    
    # Marcar seleccionados como "y"
    # whiptail devuelve: "tag1" "tag2" ...
    for item in $sel; do
        # Quitar comillas
        item=$(echo "$item" | tr -d '"')
        i=0
        while [[ $i -lt ${#items[@]} ]]; do
            local tag="${items[$i]}"
            local var="${items[$((i+2))]}"
            if [[ "$tag" == "$item" ]]; then
                declare -gx "$var=y"
                break
            fi
            i=$((i + 3))
        done
    done
    
    return 0
}

run_addon_modules() {
    local logfile="/tmp/pi-linux-addon.log"
    > "$logfile"
    
    for module in "${SCRIPT_DIR}/modules/04-software.sh" "${SCRIPT_DIR}/modules/05-software.sh"; do
        if [[ -f "$module" ]]; then
            (
                bash "$module" >> "$logfile" 2>&1
            ) &
            local pid=$!
            local basename_module
            basename_module=$(basename "$module")
            
            {
                while kill -0 $pid 2>/dev/null; do
                    local lastline
                    lastline=$(tail -n 1 "$logfile" 2>/dev/null | cut -c1-60)
                    echo -e "XXX\n0\nInstalando software adicional...\n$basename_module\n\n$lastline\nXXX"
                    sleep 2
                done
            } | $TUI $ARGS --title "Software Adicional" --gauge "\nInstalando..." $((H + 6)) $W 0
            
            wait $pid
        fi
    done
}

# ============================================
# FLUJO PRINCIPAL
# ============================================

main() {
    # Verificar root
    if [[ $EUID -ne 0 ]]; then
        echo "Este script debe ejecutarse como root (sudo)"
        exit 1
    fi
    
    # Verificar Arch
    if [[ ! -f /etc/arch-release ]]; then
        echo "Este instalador solo funciona en Arch Linux"
        exit 1
    fi
    
    # Detectar si ya se ejecutó anteriormente
    if tracker_was_run 2>/dev/null; then
        step_welcome_rerun
        
        local rerun_mode
        rerun_mode=$(step_rerun_menu)
        
        case "$rerun_mode" in
            addon)
                if step_addon; then
                    run_addon_modules
                    tracker_save_installation 2>/dev/null || true
                    tui_msg "Completado" "
✅ Software adicional instalado!

Los paquetes seleccionados han sido
instalados correctamente."
                else
                    tui_msg "Cancelado" "No se instaló ningún software adicional."
                fi
                exit 0
                ;;
            full)
                # Continuar con flujo normal
                ;;
            summary)
                local summary_date summary_user summary_de summary_rice summary_gpu
                summary_date=$(tracker_get_var "INSTALL_DATE" "desconocida")
                summary_user=$(tracker_get_var "USERNAME" "desconocido")
                summary_de=$(tracker_get_var "DESKTOP_ENV" "-")
                summary_rice=$(tracker_get_var "RICE_TYPE" "-")
                summary_gpu=$(tracker_get_var "GPU_TYPE" "-")
                
                tui_msg "Resumen de Instalación" "
📋 Instalación previa:

  Fecha: $summary_date
  Usuario: $summary_user
  DE: $summary_de
  Rice: $summary_rice
  GPU: $summary_gpu

Pulsa OK para volver al menú principal."
                main "$@"
                return
                ;;
            reset)
                if tui_yesno "Confirmar" "¿Borrar el historial de instalación previa?\n\nEsto hará que la próxima ejecución sea como la primera vez."; then
                    rm -f "$PI_TRACKER_FILE"
                    tui_msg "Completado" "Historial de instalación borrado."
                fi
                main "$@"
                return
                ;;
            *)
                exit 0
                ;;
        esac
    fi
    
    step_welcome
    
    local mode
    mode=$(step_mode)
    
    local de=""
    local rice=""
    local gpu="auto"
    
    case "$mode" in
        auto)
            de="plasma"
            rice="sweet"
            gpu="auto"
            ;;
            
        express)
            local preset
            preset=$(step_express)
            case "$preset" in
                hyprland-hyde)
                    de="hyprland"
                    rice="hyde"
                    ;;
                gnome-whitesur)
                    de="gnome"
                    rice="whitesur"
                    ;;
                plasma-sweet)
                    de="plasma"
                    rice="sweet"
                    ;;
                plasma-catppuccin)
                    de="plasma"
                    rice="catppuccin"
                    ;;
            esac
            gpu="auto"
            ;;
            
        advanced)
            de=$(step_desktop_env)
            case "$de" in
                plasma)
                    rice=$(step_rice_plasma)
                    ;;
                gnome)
                    rice=$(step_rice_gnome)
                    ;;
                hyprland)
                    rice=$(step_rice_hyprland)
                    ;;
            esac
            gpu=$(step_gpu)
            ;;
            
        unattended)
            bash "$PI_LINUX" --unattended
            exit 0
            ;;
    esac
    
    # Preguntar usuario del sistema antes de confirmar
    step_username
    
    # Selección de software adicional (opcional)
    local software_sel
    software_sel=$(step_software)
    
    # Mapear selección de whiptail a variables INSTALL_*
    for item in $software_sel; do
        item=$(echo "$item" | tr -d '"')
        case "$item" in
            chrome)    INSTALL_CHROME="y" ;;
            brave)     INSTALL_BRAVE="y" ;;
            firefox)   INSTALL_FIREFOX="y" ;;
            vscode)    INSTALL_VSCODE="y" ;;
            spotify)   INSTALL_SPOTIFY="y" ;;
            docker)    INSTALL_DOCKER="y" ;;
            nvim)      INSTALL_NEOVIM="y" ;;
            zsh)       INSTALL_ZSH="y" ; INSTALL_OHMYZSH="y" ;;
            tmux)      INSTALL_TMUX="y" ; INSTALL_OHMYTMUX="y" ;;
            fzf)       INSTALL_FZF="y" ;;
            btop)      INSTALL_BTOP="y" ;;
            starship)  INSTALL_STARSHIP="y" ;;
        esac
    done
    
    if step_confirm "$de" "$rice" "$gpu"; then
        # Guardar selección en unattended.conf temporal
        cat > "${SCRIPT_DIR}/config/unattended.conf" <<EOF
#!/bin/bash
DESKTOP_ENV="${de}"
THEME="${rice}"
RICE_TYPE="${rice}"
HYPR_RICE="${rice}"
GNOME_RICE="${rice}"
PLASMA_RICE="${rice}"
GPU_TYPE="${gpu}"
SDDM_THEME="astronaut"
INSTALL_GNOME_EXTENSIONS="y"
INSTALL_CHROME="${INSTALL_CHROME:-n}"
INSTALL_BRAVE="${INSTALL_BRAVE:-n}"
INSTALL_FIREFOX="${INSTALL_FIREFOX:-y}"
INSTALL_VSCODE="${INSTALL_VSCODE:-y}"
INSTALL_OBSIDIAN="${INSTALL_OBSIDIAN:-n}"
INSTALL_VLC="${INSTALL_VLC:-y}"
INSTALL_SPOTIFY="${INSTALL_SPOTIFY:-n}"
INSTALL_OBS="${INSTALL_OBS:-n}"
INSTALL_KITTY="${INSTALL_KITTY:-y}"
INSTALL_ALACRITTY="${INSTALL_ALACRITTY:-n}"
INSTALL_DOCKER="${INSTALL_DOCKER:-y}"
INSTALL_NODEJS="${INSTALL_NODEJS:-y}"
INSTALL_PYTHON="${INSTALL_PYTHON:-y}"
INSTALL_FZF="${INSTALL_FZF:-y}"
INSTALL_RIPGREP="${INSTALL_RIPGREP:-y}"
INSTALL_FD="${INSTALL_FD:-y}"
INSTALL_BAT="${INSTALL_BAT:-y}"
INSTALL_EZA="${INSTALL_EZA:-y}"
INSTALL_ZOXIDE="${INSTALL_ZOXIDE:-y}"
INSTALL_ATUIN="${INSTALL_ATUIN:-n}"
INSTALL_DELTA="${INSTALL_DELTA:-n}"
INSTALL_NEOVIM="${INSTALL_NEOVIM:-y}"
INSTALL_LAZYVIM="${INSTALL_LAZYVIM:-n}"
INSTALL_DOOMEMACS="${INSTALL_DOOMEMACS:-n}"
INSTALL_BTOP="${INSTALL_BTOP:-y}"
INSTALL_NVTOP="${INSTALL_NVTOP:-y}"
INSTALL_ZSH="${INSTALL_ZSH:-y}"
INSTALL_OHMYZSH="${INSTALL_OHMYZSH:-y}"
INSTALL_FISH="${INSTALL_FISH:-n}"
INSTALL_STARSHIP="${INSTALL_STARSHIP:-y}"
INSTALL_TMUX="${INSTALL_TMUX:-y}"
INSTALL_OHMYTMUX="${INSTALL_OHMYTMUX:-n}"
USERNAME="${USERNAME:-${SUDO_USER:-user}}"
HOSTNAME="pi-linux"
TIMEZONE="Europe/Madrid"
LOCALE="es_ES.UTF-8"
KEYMAP="es"
EOF
        
        bash "$PI_LINUX" --unattended
        
        tui_msg "Completado" "
✅ Instalación completada!

Reinicia el sistema para comenzar:
  systemctl reboot

Tu nuevo escritorio te espera en SDDM 🥧"
    else
        tui_msg "Cancelado" "Instalación cancelada por el usuario."
        exit 0
    fi
}

main "$@"
