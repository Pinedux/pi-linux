#!/bin/bash
# Módulo 02: Drivers GPU

set -e
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/pi-linux-common.sh"

GPU_TYPE="${GPU_TYPE:-auto}"

banner "Módulo 02: Drivers GPU ($GPU_TYPE)"

# ============================================
# DETECTAR GPU SI ES AUTO
# ============================================

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
    export GPU_TYPE
fi

# ============================================
# INSTALAR DRIVERS SEGÚN GPU
# ============================================

case "$GPU_TYPE" in
    nvidia)
        info "Instalando drivers NVIDIA..."
        
        install_pkg \
            nvidia-dkms \
            nvidia-utils \
            nvidia-settings \
            lib32-nvidia-utils \
            opencl-nvidia \
            libvdpau-va-gl \
            nvtop
        
        # Configuración de NVIDIA
        cat > /etc/modprobe.d/nvidia.conf << 'NVCONF'
options nvidia-drm modeset=1
options nvidia NVreg_UsePageAttributeTable=1
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
        
        mkinitcpio -P
        success "Drivers NVIDIA instalados"
        ;;
        
    nvidia-open)
        info "Instalando drivers NVIDIA (open)..."
        
        install_pkg \
            nvidia-open-dkms \
            nvidia-open-utils \
            nvidia-settings \
            lib32-nvidia-utils \
            opencl-nvidia \
            libvdpau-va-gl \
            nvtop
        
        # Configuración de NVIDIA
        cat > /etc/modprobe.d/nvidia.conf << 'NVCONF'
options nvidia-drm modeset=1
options nvidia NVreg_UsePageAttributeTable=1
NVCONF
        
        # Hook de mkinitcpio para NVIDIA
        mkdir -p /etc/pacman.d/hooks
        cat > /etc/pacman.d/hooks/nvidia.hook << 'HOOK'
[Trigger]
Operation=Install
Operation=Upgrade
Operation=Remove
Type=Package
Target=nvidia-open-dkms
Target=linux

[Action]
Description=Update NVIDIA module in initcpio
Depends=mkinitcpio
When=PostTransaction
NeedsTargets
Exec=/bin/sh -c 'while read -r trg; do case $trg in linux*) exit 0; esac; done; /usr/bin/mkinitcpio -P'
HOOK
        
        mkinitcpio -P
        success "Drivers NVIDIA (open) instalados"
        ;;
        
    amd)
        info "Instalando drivers AMD..."
        
        install_pkg \
            mesa \
            lib32-mesa \
            xf86-video-amdgpu \
            vulkan-radeon \
            lib32-vulkan-radeon \
            vulkan-icd-loader \
            lib32-vulkan-icd-loader \
            libva-mesa-driver \
            lib32-libva-mesa-driver \
            mesa-vdpau \
            lib32-mesa-vdpau \
            nvtop
        
        success "Drivers AMD instalados"
        ;;
        
    intel)
        info "Instalando drivers Intel..."
        
        install_pkg \
            mesa \
            lib32-mesa \
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
            install_pkg virtualbox-guest-utils
            systemctl enable vboxservice
        elif lspci | grep -i vmware &>/dev/null; then
            install_pkg open-vm-tools
            systemctl enable vmtoolsd
        elif lspci | grep -i qemu &>/dev/null; then
            install_pkg qemu-guest-agent
            systemctl enable qemu-guest-agent
        fi
        
        success "Drivers VM instalados"
        ;;
        
    generic|*)
        info "Instalando drivers genéricos..."
        
        install_pkg \
            mesa \
            lib32-mesa \
            xf86-video-vesa \
            xf86-video-fbdev
        
        success "Drivers genéricos instalados"
        ;;
esac

success "Módulo GPU completado"
