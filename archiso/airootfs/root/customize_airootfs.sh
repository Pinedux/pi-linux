#!/usr/bin/env bash
# Pi-Linux Live Desktop Setup — Build-time configuration (minimal)
# Solo ajusta permisos que no pueden hacerse estáticamente.
set -e

echo "[customize_airootfs] Ajustando permisos del entorno live..."

# Asegurar que liveuser existe (por si acaso)
if ! id liveuser >/dev/null 2>&1; then
    useradd -m -G wheel,audio,video,storage,optical,network,users -s /bin/bash liveuser
    echo "liveuser:live" | chpasswd
fi

# Corregir propiedad del home de liveuser
chown -R liveuser:liveuser /home/liveuser

# Asegurar permisos de sudoers
chmod 440 /etc/sudoers.d/99-liveuser 2>/dev/null || true

echo "[customize_airootfs] Permisos ajustados correctamente."
