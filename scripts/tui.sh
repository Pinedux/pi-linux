#!/bin/bash
# Pi-Linux TUI Installer
# Interfaz de usuario en modo texto con whiptail/dialog

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PI_LINUX="${SCRIPT_DIR}/pi-linux.sh"

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

Si el usuario no existe, se creará automáticamente." $((H + 4)) $W "${SUDO_USER:-pinedux}")
    
    if [[ -z "$user_input" ]]; then
        user_input="${SUDO_USER:-pinedux}"
    fi
    
    USERNAME="$user_input"
    export USERNAME
    
    # Verificar si existe
    if ! id "$USERNAME" &>/dev/null; then
        if tui_yesno "Crear Usuario" "El usuario '$USERNAME' no existe en el sistema.

¿Deseas crearlo ahora?"; then
            useradd -m -G wheel,audio,video,storage,optical,network -s /bin/bash "$USERNAME" 2>/dev/null || \
            useradd -m -G users,audio,video,storage -s /bin/bash "$USERNAME"
            
            $TUI $ARGS --title "Contraseña" --passwordbox "
Establece una contraseña para $USERNAME:" $H $W 2>/dev/null || true
            
            # Asegurar sudo para wheel
            if [[ -f /etc/sudoers ]] && ! grep -q "^%wheel" /etc/sudoers; then
                echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers
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
    
    # Exportar variables para que pi-linux.sh las use
    export DESKTOP_ENV="$de"
    export RICE_TYPE="$rice"
    export THEME="$rice"
    export GPU_TYPE="$gpu"
    export HYPR_RICE="$rice"
    
    # Ejecutar el instalador principal
    bash "$PI_LINUX" --unattended 2>&1 | \
        $TUI $ARGS --title "Instalando..." --gauge "
Instalando Pi-Linux:
  DE:   $de
  Rice: $rice

Esto puede tardar varios minutos..." $((H + 4)) $W 0 || true
    
    # Si falla el gauge, ejecutar normal
    if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
        bash "$PI_LINUX" --unattended
    fi
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
INSTALL_CHROME="n"
INSTALL_BRAVE="n"
INSTALL_FIREFOX="y"
INSTALL_VSCODE="y"
INSTALL_OBSIDIAN="n"
INSTALL_VLC="y"
INSTALL_SPOTIFY="n"
INSTALL_OBS="n"
INSTALL_KITTY="y"
INSTALL_ALACRITTY="n"
INSTALL_DOCKER="y"
INSTALL_NODEJS="y"
INSTALL_PYTHON="y"
INSTALL_FZF="y"
INSTALL_RIPGREP="y"
INSTALL_FD="y"
INSTALL_BAT="y"
INSTALL_EZA="y"
INSTALL_ZOXIDE="y"
INSTALL_ATUIN="n"
INSTALL_DELTA="n"
INSTALL_NEOVIM="y"
INSTALL_LAZYVIM="n"
INSTALL_DOOMEMACS="n"
INSTALL_BTOP="y"
INSTALL_NVTOP="y"
INSTALL_ZSH="y"
INSTALL_OHMYZSH="y"
INSTALL_FISH="n"
INSTALL_STARSHIP="y"
INSTALL_TMUX="y"
INSTALL_OHMYTMUX="n"
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
