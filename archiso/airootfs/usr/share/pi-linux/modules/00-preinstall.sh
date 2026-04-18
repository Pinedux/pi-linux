#!/bin/bash
# Módulo 00: Preparación del Sistema

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/pi-linux-common.sh"

banner "Módulo 00: Preparación del Sistema"

info "Actualizando sistema..."
pacman -Syu --noconfirm
success "Sistema actualizado"
