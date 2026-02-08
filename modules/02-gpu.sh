#!/bin/bash
set -e
GPU_TYPE="${GPU_TYPE:-generic}"
echo "[02] GPU: $GPU_TYPE"
case "$GPU_TYPE" in
    nvidia) pacman -S --needed --noconfirm nvidia-dkms nvidia-utils ;;
    amd) pacman -S --needed --noconfirm mesa xf86-video-amdgpu ;;
    intel) pacman -S --needed --noconfirm mesa xf86-video-intel ;;
esac
echo "[✓] GPU configurada"
