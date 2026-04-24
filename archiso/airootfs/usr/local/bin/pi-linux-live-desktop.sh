#!/bin/bash
# Pi-Linux Live Desktop Setup
# Configura el entorno portable del live USB al arrancar

set -e

LIVE_USER="liveuser"
LIVE_PASS="live"
SETUP_MARKER="/var/lib/pi-linux-live-setup"

# Evitar ejecuciones repetidas
if [[ -f "$SETUP_MARKER" ]]; then
    exit 0
fi

echo "[Pi-Linux Live] Configurando entorno de escritorio..."

# ============================================
# DESHABILITAR GETTY@TTY1 (no competir con SDDM)
# ============================================
systemctl disable getty@tty1 --now 2>/dev/null || true

# ============================================
# CREAR USUARIO LIVE
# ============================================
if ! id "$LIVE_USER" &>/dev/null; then
    useradd -m -G wheel,audio,video,storage,optical,network -s /bin/bash "$LIVE_USER"
    echo "${LIVE_USER}:${LIVE_PASS}" | chpasswd
    echo "[Pi-Linux Live] Usuario ${LIVE_USER} creado"
fi

# ============================================
# AUTologin SDDM
# ============================================
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/autologin.conf <<EOF
[Autologin]
User=${LIVE_USER}
Session=plasma.desktop
Relogin=false

[General]
Numlock=on
EOF

# ============================================
# CONFIGURAR PLASMA (tema oscuro básico)
# ============================================
USER_HOME="/home/${LIVE_USER}"
mkdir -p "${USER_HOME}/.config"

# Plasma: tema oscuro por defecto
cat > "${USER_HOME}/.config/kwinrc" <<EOF
[compositing]
OpenGLIsUnsafe=false

[org.kde.kdecoration2]
ButtonsOnLeft=
ButtonsOnRight=IAX
CloseOnDoubleClickOnMenu=false
ShowToolTips=true
library=org.kde.breeze
theme=Breeze
EOF

cat > "${USER_HOME}/.config/plasmarc" <<EOF
[Theme]
name=default
useGlobalTheme=true
EOF

# Fondo de pantalla
mkdir -p "${USER_HOME}/.config/plasma-workspace/env"
cat > "${USER_HOME}/.config/plasma-workspace/env/wallpaper.sh" <<'EOF'
#!/bin/bash
qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
var allDesktops = desktops();
for (i=0;i<allDesktops.length;i++) {
    d = allDesktops[i];
    d.wallpaperPlugin = "org.kde.image";
    d.currentConfigGroup = Array("Wallpaper", "org.kde.image", "General");
    d.writeConfig("Image", "file:///usr/share/backgrounds/pi-linux/pi-linux-live-bg.png");
}'
EOF
chmod +x "${USER_HOME}/.config/plasma-workspace/env/wallpaper.sh"

# ============================================
# ICONO DE INSTALACIÓN EN EL ESCRITORIO
# ============================================
mkdir -p "${USER_HOME}/Desktop"
cat > "${USER_HOME}/Desktop/Install-Pi-Linux.desktop" <<EOF
[Desktop Entry]
Name=Install Pi-Linux to Disk
Name[es]=Instalar Pi-Linux en disco
Comment=Install Arch Linux with Pi-Linux rices
Comment[es]=Instalar Arch Linux con rices Pi-Linux
Exec=konsole -e /usr/local/bin/pi-linux-installer
Icon=system-software-install
Type=Application
Terminal=false
Categories=System;
EOF
chmod +x "${USER_HOME}/Desktop/Install-Pi-Linux.desktop"

# ============================================
# PERMISOS
# ============================================
chown -R "${LIVE_USER}:${LIVE_USER}" "${USER_HOME}"

# Permitir sudo sin password para liveuser
cat > /etc/sudoers.d/99-liveuser <<EOF
${LIVE_USER} ALL=(ALL) NOPASSWD: ALL
EOF
chmod 440 /etc/sudoers.d/99-liveuser

# ============================================
# SERVICIOS
# ============================================
systemctl enable sddm --force 2>/dev/null || true
systemctl enable NetworkManager 2>/dev/null || true

# Marcar setup completado
touch "$SETUP_MARKER"
echo "[Pi-Linux Live] Setup completado."
