# ============================================
cat > "$INSTALL_DIR/modules/02-gpu.sh" << 'EOF'
#!/bin/bash
# Módulo 02: Instalación de drivers GPU

set -e

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}Módulo 02: Drivers GPU${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Detectar GPU si es auto
if [[ "$GPU_TYPE" == "auto" ]] || [[ -z "$GPU_TYPE" ]]; then
    info "Detectando GPU..."
    if lspci | grep -i nvidia &>/dev/null; then
        GPU_TYPE="nvidia"
    elif lspci | grep -i amd &>/dev/null; then
        GPU_TYPE="amd"
    elif lspci | grep -i intel &>/dev/null; then
        GPU_TYPE="intel"
    else
        GPU_TYPE="generic"
    fi
    info "GPU detectada: $GPU_TYPE"
fi

case "$GPU_TYPE" in
    nvidia|nvidia-open)
        info "Instalando drivers NVIDIA..."
        
        # Instalar drivers NVIDIA
        pacman -S --needed --noconfirm \
            nvidia-dkms \
            nvidia-utils \
            nvidia-settings \
            lib32-nvidia-utils \
            opencl-nvidia \
            libvdpau-va-gl
        
        # Configuración de NVIDIA
        cat > /etc/modprobe.d/nvidia.conf << 'NVCONF'
options nvidia-drm modeset=1
options nvidia NVreg_UsePageAttributeTable=1
options nvidia NVreg_RegistryDwords="PowerMizerEnable=0x1; PerfLevelSrc=0x2222; PowerMizerDefaultAC=0x1"
NVCONF
        
        # Hook de mkinitcpio para NVIDIA
        mkdir -p /etc/pacman.d/hooks
        cat > /etc/pacman.d/hooks/nvidia.hook << 'HOOK'
[Trigger]
Operation=Install
Operation=Upgrade
Operation=Remove
Type=Package
Target=nvidia-dkms
Target=linux

[Action]
Description=Update NVIDIA module in initcpio
Depends=mkinitcpio
When=PostTransaction
NeedsTargets
Exec=/bin/sh -c 'while read -r trg; do case $trg in linux*) exit 0; esac; done; /usr/bin/mkinitcpio -P'
HOOK
        
        # Regenerar initramfs
        mkinitcpio -P
        
        success "Drivers NVIDIA instalados"
        ;;
        
    amd)
        info "Instalando drivers AMD/ATI..."
        
        pacman -S --needed --noconfirm \
            mesa \
            lib32-mesa \
            xf86-video-amdgpu \
            xf86-video-ati \
            vulkan-radeon \
            lib32-vulkan-radeon \
            vulkan-icd-loader \
            lib32-vulkan-icd-loader \
            libva-mesa-driver \
            lib32-libva-mesa-driver \
            mesa-vdpau \
            lib32-mesa-vdpau \
            opencl-amd 2>/dev/null || true
        
        success "Drivers AMD instalados"
        ;;
        
    intel)
        info "Instalando drivers Intel..."
        
        pacman -S --needed --noconfirm \
            mesa \
            lib32-mesa \
            xf86-video-intel \
            vulkan-intel \
            lib32-vulkan-intel \
            vulkan-icd-loader \
            lib32-vulkan-icd-loader \
            intel-media-driver \
            libva-intel-driver \
            libva-utils
        
        success "Drivers Intel instalados"
        ;;
        
    vm)
        info "Instalando drivers para máquina virtual..."
        
        if lspci | grep -i virtualbox &>/dev/null; then
            pacman -S --needed --noconfirm \
                virtualbox-guest-utils
            systemctl enable vboxservice
        elif lspci | grep -i vmware &>/dev/null; then
            pacman -S --needed --noconfirm \
                open-vm-tools
            systemctl enable vmtoolsd
        elif lspci | grep -i qemu &>/dev/null; then
            pacman -S --needed --noconfirm \
                qemu-guest-agent
            systemctl enable qemu-guest-agent
        fi
        
        success "Drivers VM instalados"
        ;;
        
    generic|*)
        info "Instalando drivers genéricos..."
        
        pacman -S --needed --noconfirm \
            mesa \
            lib32-mesa \
            xf86-video-vesa \
            xf86-video-fbdev
        
        success "Drivers genéricos instalados"
        ;;
esac

# Instalar utilidades comunes
info "Instalando utilidades de GPU..."
pacman -S --needed --noconfirm \
    mesa-demos \
    glxinfo \
    vulkan-tools \
    libva-utils

success "Módulo GPU completado"
