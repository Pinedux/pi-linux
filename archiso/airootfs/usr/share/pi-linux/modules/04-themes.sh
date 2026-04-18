#!/bin/bash
# Módulo 04: Rices Completos por Entorno de Escritorio
# Instala temas GTK/Shell/Icons/Extensions para GNOME,
# Global Themes/Kvantum/Aurorae para Plasma,
# y configura SDDM para que empareje con el rice seleccionado.

set -e
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/pi-linux-common.sh"

THEME="${THEME:-none}"
DESKTOP_ENV="${DESKTOP_ENV:-plasma}"
RICE_TYPE="${RICE_TYPE:-$THEME}"
INSTALL_GNOME_EXTENSIONS="${INSTALL_GNOME_EXTENSIONS:-y}"

banner "Módulo 04: Rice Completo ($DESKTOP_ENV → $RICE_TYPE)"

# ============================================
# ASEGURAR YAY
# ============================================

ensure_yay

# ============================================
# HELPER: INSTALAR TEMA SDDM EMPAREJADO
# ============================================

install_sddm_matched_theme() {
    local theme_key="$1"
    info "Configurando tema SDDM emparejado: $theme_key"
    
    case "$theme_key" in
        whitesur)
            # WhiteSur tiene SDDM theme en su repo KDE
            if [[ ! -d "/usr/share/sddm/themes/WhiteSur" ]]; then
                local tmpdir
                tmpdir=$(mktemp -d)
                pi_clone "https://github.com/vinceliuice/WhiteSur-kde.git" "$tmpdir/WhiteSur-kde"
                (
                    cd "$tmpdir/WhiteSur-kde"
                    ./install.sh --sddm 2>/dev/null || true
                )
                rm -rf "$tmpdir"
            fi
            sddm_set_theme "WhiteSur" 2>/dev/null || true
            ;;
            
        sweet)
            # Sweet SDDM
            install_aur sweet-kde-theme-git 2>/dev/null || true
            sddm_set_theme "Sweet" 2>/dev/null || true
            ;;
            
        layan)
            install_aur layan-kde-theme-git 2>/dev/null || true
            sddm_set_theme "Layan" 2>/dev/null || true
            ;;
            
        orchis)
            install_aur orchis-kde-theme-git 2>/dev/null || true
            sddm_set_theme "Orchis" 2>/dev/null || true
            ;;
            
        catppuccin)
            # SilentSDDM con preset catppuccin es popular
            if [[ ! -d "/usr/share/sddm/themes/SilentSDDM" ]]; then
                local tmpdir
                tmpdir=$(mktemp -d)
                pi_clone "https://github.com/semihsigma/SilentSDDM.git" "$tmpdir/SilentSDDM"
                mkdir -p /usr/share/sddm/themes/SilentSDDM
                cp -r "$tmpdir/SilentSDDM/"* /usr/share/sddm/themes/SilentSDDM/ 2>/dev/null || true
                rm -rf "$tmpdir"
            fi
            sddm_set_theme "SilentSDDM" 2>/dev/null || true
            ;;
            
        *)
            # Fallback al tema astronaut moderno
            sddm_set_theme "sddm-astronaut-theme"
            ;;
    esac
}

# ============================================
# GNOME: RICE COMPLETO
# ============================================

apply_gnome_rice() {
    local rice="$1"
    info "Aplicando rice GNOME: $rice"
    
    # Instalar dependencias comunes
    install_pkg gnome-browser-connector gnome-shell-extensions
    
    # Instalar Bibata cursor si no existe
    install_aur bibata-cursor-theme 2>/dev/null || true
    
    case "$rice" in
        whitesur)
            info "Instalando WhiteSur para GNOME..."
            local tmpdir
            tmpdir=$(mktemp -d)
            pi_clone "https://github.com/vinceliuice/WhiteSur-gtk-theme.git" "$tmpdir/WhiteSur"
            (
                cd "$tmpdir/WhiteSur"
                ./install.sh -t all -l 2>/dev/null || true
                sudo ./install.sh -d /usr/share/themes 2>/dev/null || true
                ./tweaks.sh -f 2>/dev/null || true
            )
            
            # Iconos
            pi_clone "https://github.com/vinceliuice/WhiteSur-icon-theme.git" "$tmpdir/WhiteSur-icons"
            (
                cd "$tmpdir/WhiteSur-icons"
                ./install.sh -d "${PI_USER_HOME}/.icons" 2>/dev/null || true
                ./install.sh -d /usr/share/icons --sudo 2>/dev/null || true
            )
            
            rm -rf "$tmpdir"
            
            # Aplicar
            gnome_set_theme "WhiteSur-Dark" "WhiteSur" "Bibata-Modern-Ice" "WhiteSur-Dark"
            ;;
            
        orchis)
            info "Instalando Orchis para GNOME..."
            local tmpdir
            tmpdir=$(mktemp -d)
            pi_clone "https://github.com/vinceliuice/Orchis-theme.git" "$tmpdir/Orchis"
            (
                cd "$tmpdir/Orchis"
                ./install.sh -t all -c all -l 2>/dev/null || true
                ./install.sh --tweaks macos 2>/dev/null || true
            )
            
            # Iconos Tela
            pi_clone "https://github.com/vinceliuice/Tela-icon-theme.git" "$tmpdir/Tela"
            (
                cd "$tmpdir/Tela"
                ./install.sh -d "${PI_USER_HOME}/.icons" 2>/dev/null || true
                ./install.sh -d /usr/share/icons --sudo 2>/dev/null || true
            )
            
            rm -rf "$tmpdir"
            
            gnome_set_theme "Orchis-Dark" "Tela-black-dark" "Bibata-Modern-Ice" "Orchis-Dark"
            ;;
            
        graphite)
            info "Instalando Graphite para GNOME..."
            local tmpdir
            tmpdir=$(mktemp -d)
            pi_clone "https://github.com/vinceliuice/Graphite-gtk-theme.git" "$tmpdir/Graphite"
            (
                cd "$tmpdir/Graphite"
                ./install.sh -t all --tweaks nord rimless -l 2>/dev/null || true
                ./install.sh -i -d "${PI_USER_HOME}/.icons" 2>/dev/null || true
            )
            rm -rf "$tmpdir"
            
            gnome_set_theme "Graphite-Dark" "Graphite-dark" "Bibata-Modern-Ice" "Graphite-Dark"
            ;;
            
        catppuccin)
            info "Instalando Catppuccin para GNOME..."
            local tmpdir
            tmpdir=$(mktemp -d)
            pi_clone "https://github.com/catppuccin/gtk.git" "$tmpdir/catppuccin-gtk"
            (
                cd "$tmpdir/catppuccin-gtk"
                # Requiere python para el instalador
                install_pkg python
                python install.py mocha -a blue 2>/dev/null || true
            )
            
            # Iconos Catppuccin
            install_aur catppuccin-papirus-folders 2>/dev/null || true
            
            rm -rf "$tmpdir"
            
            gnome_set_theme "Catppuccin-Mocha" "Papirus-Dark" "Bibata-Modern-Ice"
            ;;
            
        nordic)
            info "Instalando Nordic para GNOME..."
            local tmpdir
            tmpdir=$(mktemp -d)
            cd "$tmpdir"
            curl -L -o Nordic.tar.xz "https://github.com/EliverLara/Nordic/releases/latest/download/Nordic.tar.xz" 2>/dev/null || true
            mkdir -p "${PI_USER_HOME}/.themes" /usr/share/themes
            tar -xf Nordic.tar.xz -C "${PI_USER_HOME}/.themes/" 2>/dev/null || true
            cp -r "${PI_USER_HOME}/.themes/Nordic" /usr/share/themes/ 2>/dev/null || true
            
            # Iconos Papirus (empareja bien con Nordic)
            install_pkg papirus-icon-theme
            
            rm -rf "$tmpdir"
            
            gnome_set_theme "Nordic" "Papirus" "Bibata-Modern-Ice"
            ;;
            
        *)
            warning "Rice GNOME no reconocido: $rice"
            ;;
    esac
    
    # ============================================
    # EXTENSIONS GNOME ESENCIALES
    # ============================================
    
    if [[ "${INSTALL_GNOME_EXTENSIONS}" == "y" ]]; then
        info "Instalando extensions GNOME esenciales..."
        
        # Algunas están en repos de Arch
        install_pkg \
            gnome-shell-extensions \
            gnome-shell-extension-dash-to-dock \
            gnome-shell-extension-blur-my-shell \
            gnome-shell-extension-user-theme \
            2>/dev/null || true
        
        # Activar extensions vía gsettings (solo si hay sesión dbus)
        sudo -u "${PI_REAL_USER}" DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u "$PI_REAL_USER")/bus \
            gsettings set org.gnome.shell enabled-extensions "[
                'user-theme@gnome-shell-extensions.gcampax.github.com',
                'dash-to-dock@micxgx.gmail.com',
                'blur-my-shell@aunetx',
                'just-perfection-desktop@just-perfection'
            ]" 2>/dev/null || warning "No se pudieron activar extensions (requiere sesión activa)"
        
        # Configurar Dash to Dock
        sudo -u "${PI_REAL_USER}" DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u "$PI_REAL_USER")/bus \
            gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM' 2>/dev/null || true
        sudo -u "${PI_REAL_USER}" DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u "$PI_REAL_USER")/bus \
            gsettings set org.gnome.shell.extensions.dash-to-dock extend-height false 2>/dev/null || true
        sudo -u "${PI_REAL_USER}" DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u "$PI_REAL_USER")/bus \
            gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 48 2>/dev/null || true
        
        success "Extensions GNOME configuradas"
    fi
    
    install_sddm_matched_theme "$rice"
    success "Rice GNOME completado"
}

# ============================================
# PLASMA: RICE COMPLETO
# ============================================

apply_plasma_rice() {
    local rice="$1"
    info "Aplicando rice Plasma: $rice"
    
    # Dependencias comunes
    install_pkg kvantum kvantum-qt5 qt5ct qt6ct
    
    # Cursor Bibata
    install_aur bibata-cursor-theme 2>/dev/null || true
    
    case "$rice" in
        whitesur)
            info "Instalando WhiteSur para Plasma..."
            local tmpdir
            tmpdir=$(mktemp -d)
            pi_clone "https://github.com/vinceliuice/WhiteSur-kde.git" "$tmpdir/WhiteSur-kde"
            (
                cd "$tmpdir/WhiteSur-kde"
                ./install.sh 2>/dev/null || true
            )
            rm -rf "$tmpdir"
            
            # Iconos y cursor
            local tmpdir2
            tmpdir2=$(mktemp -d)
            pi_clone "https://github.com/vinceliuice/WhiteSur-icon-theme.git" "$tmpdir2/WhiteSur-icons"
            (
                cd "$tmpdir2/WhiteSur-icons"
                ./install.sh -d "${PI_USER_HOME}/.icons" 2>/dev/null || true
            )
            rm -rf "$tmpdir2"
            
            plasma_apply_global_theme "com.github.vinceliuice.WhiteSur" 2>/dev/null || true
            ;;
            
        mactahoe)
            info "Instalando MacTahoe para Plasma..."
            local tmpdir
            tmpdir=$(mktemp -d)
            pi_clone "https://github.com/vinceliuice/MacTahoe-kde.git" "$tmpdir/MacTahoe-kde"
            (
                cd "$tmpdir/MacTahoe-kde"
                ./install.sh 2>/dev/null || true
            )
            rm -rf "$tmpdir"
            plasma_apply_global_theme "com.github.vinceliuice.MacTahoe" 2>/dev/null || true
            ;;
            
        sweet)
            info "Instalando Sweet para Plasma..."
            install_aur sweet-kde-theme-git 2>/dev/null || true
            install_aur candy-icons-git 2>/dev/null || true
            
            # Kvantum Sweet
            local tmpdir
            tmpdir=$(mktemp -d)
            pi_clone "https://github.com/EliverLara/Sweet.git" "$tmpdir/Sweet"
            mkdir -p "${PI_USER_HOME}/.config/Kvantum"
            cp -r "$tmpdir/Sweet/kde/Kvantum/Sweet" "${PI_USER_HOME}/.config/Kvantum/" 2>/dev/null || true
            chown -R "${PI_REAL_USER}:${PI_REAL_USER}" "${PI_USER_HOME}/.config/Kvantum"
            rm -rf "$tmpdir"
            
            plasma_apply_global_theme "Sweet" 2>/dev/null || true
            ;;
            
        layan)
            info "Instalando Layan para Plasma..."
            install_aur layan-kde-theme-git 2>/dev/null || true
            
            # Iconos Tela
            local tmpdir
            tmpdir=$(mktemp -d)
            pi_clone "https://github.com/vinceliuice/Tela-icon-theme.git" "$tmpdir/Tela"
            (
                cd "$tmpdir/Tela"
                ./install.sh -d "${PI_USER_HOME}/.icons" 2>/dev/null || true
            )
            rm -rf "$tmpdir"
            
            plasma_apply_global_theme "Layan" 2>/dev/null || true
            ;;
            
        orchis)
            info "Instalando Orchis para Plasma..."
            install_aur orchis-kde-theme-git 2>/dev/null || true
            
            local tmpdir
            tmpdir=$(mktemp -d)
            pi_clone "https://github.com/vinceliuice/Tela-icon-theme.git" "$tmpdir/Tela"
            (
                cd "$tmpdir/Tela"
                ./install.sh -d "${PI_USER_HOME}/.icons" 2>/dev/null || true
            )
            rm -rf "$tmpdir"
            
            plasma_apply_global_theme "Orchis" 2>/dev/null || true
            ;;
            
        catppuccin)
            info "Instalando Catppuccin para Plasma..."
            local tmpdir
            tmpdir=$(mktemp -d)
            pi_clone "https://github.com/catppuccin/kde.git" "$tmpdir/catppuccin-kde"
            (
                cd "$tmpdir/catppuccin-kde"
                ./install.sh 2>/dev/null || true
            )
            rm -rf "$tmpdir"
            
            # Iconos
            install_aur catppuccin-papirus-folders 2>/dev/null || true
            
            plasma_apply_global_theme "Catppuccin-Mocha" 2>/dev/null || true
            ;;
            
        *)
            warning "Rice Plasma no reconocido: $rice"
            ;;
    esac
    
    # Aplicar cursor global
    sudo -u "${PI_REAL_USER}" kwriteconfig6 --file kcmfonts --group General --key cursorTheme "Bibata-Modern-Ice" 2>/dev/null || true
    
    install_sddm_matched_theme "$rice"
    success "Rice Plasma completado"
}

# ============================================
# DISPATCH PRINCIPAL
# ============================================

if [[ "$RICE_TYPE" == "none" ]] || [[ "$THEME" == "none" ]]; then
    info "No se instalarán rices adicionales"
    # Aún así aseguramos SDDM con astronaut
    sddm_set_theme "sddm-astronaut-theme"
    exit 0
fi

case "$DESKTOP_ENV" in
    gnome)
        apply_gnome_rice "$RICE_TYPE"
        ;;
    plasma|kde)
        apply_plasma_rice "$RICE_TYPE"
        ;;
    hyprland)
        info "Hyprland rice se instala en el módulo 06-hyprland-rice.sh"
        # Dejar SDDM con astronaut que combina bien con Hyprland
        sddm_set_theme "sddm-astronaut-theme"
        ;;
    *)
        warning "DE no soportado para rice: $DESKTOP_ENV"
        ;;
esac

success "Módulo Rice completado"
