#!/bin/bash
# Pi-Linux Disk Installer
# Instala Arch Linux base en disco desde el entorno live
# y prepara el sistema para el firstboot de Pi-Linux

set -e
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ============================================
# UTILIDADES TUI
# ============================================

if command -v whiptail &>/dev/null; then
    TUI="whiptail"
    ARGS=""
elif command -v dialog &>/dev/null; then
    TUI="dialog"
    ARGS="--stdout"
else
    TUI=""
fi

tui_msg() {
    local title="$1"
    local msg="$2"
    if [[ -n "$TUI" ]]; then
        $TUI $ARGS --title "$title" --msgbox "$msg" 20 70
    else
        echo ""
        echo "=== $title ==="
        echo "$msg"
        echo ""
        read -rp "Presiona Enter para continuar..."
    fi
}

tui_yesno() {
    local title="$1"
    local msg="$2"
    if [[ -n "$TUI" ]]; then
        $TUI $ARGS --title "$title" --yesno "$msg" 20 70
    else
        echo ""
        echo "=== $title ==="
        echo "$msg"
        read -rp "¿Continuar? [s/N]: " ans
        [[ "$ans" == "s" || "$ans" == "S" ]]
    fi
}

tui_menu() {
    local title="$1"
    local msg="$2"
    shift 2
    if [[ -n "$TUI" ]]; then
        $TUI $ARGS --title "$title" --menu "$msg" 20 70 12 "$@"
    else
        echo ""
        echo "=== $title ==="
        echo "$msg"
        local i=1
        while [[ $# -ge 2 ]]; do
            echo "  $i) $1 - $2"
            shift 2
            i=$((i+1))
        done
        read -rp "Selecciona: " sel
        echo "$sel"
    fi
}

# ============================================
# VERIFICACIONES
# ============================================

check_live() {
    if [[ ! -f /run/archiso/bootmnt/arch/boot/x86_64/vmlinuz-linux ]] && \
       [[ ! -d /run/archiso ]]; then
        if ! tui_yesno "Advertencia" \
            "No parece que estés en el entorno live de Arch/Pi-Linux.\n\nEste instalador está diseñado para ejecutarse desde el USB live.\n¿Continuar de todos modos?"; then
            exit 0
        fi
    fi
}

check_uefi() {
    if [[ -d /sys/firmware/efi ]]; then
        UEFI_MODE=true
    else
        UEFI_MODE=false
    fi
}

# ============================================
# DETECTAR DISCOS
# ============================================

list_disks() {
    lsblk -dn -o NAME,SIZE,MODEL,TYPE | awk '$4 == "disk" {print "/dev/" $1, $2 " " $3}'
}

# ============================================
# INSTALACIÓN EN DISCO
# ============================================

install_to_disk() {
    local disk="$1"
    local hostname="${2:-pi-linux}"
    local username="${3:-user}"
    local userpass="${4:-$username}"
    local timezone="${5:-Europe/Madrid}"
    local locale="${6:-es_ES.UTF-8}"
    local keymap="${7:-es}"
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  🥧  Pi-Linux Disk Installer"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  Disco:     $disk"
    echo "  UEFI:      $UEFI_MODE"
    echo "  Hostname:  $hostname"
    echo "  Usuario:   $username"
    echo "  Zona horaria: $timezone"
    echo "  Locale:    $locale"
    echo "  Keymap:    $keymap"
    echo ""
    echo "  ⚠️  ATENCIÓN: Se borrarán TODOS los datos de $disk"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    if ! tui_yesno "CONFIRMAR DESTRUCCIÓN DE DATOS" \
        "Se borrarán TODOS los datos de $disk.\n\nEsta acción NO se puede deshacer.\n\n¿Estás absolutamente seguro?"; then
        echo "Cancelado por el usuario."
        exit 0
    fi
    
    # ============================================
    # 1. PARTCIONADO
    # ============================================
    echo ""
    echo "[1/8] Particionando $disk..."
    
    # Desmontar todo lo que esté montado del disco
    umount -R "${disk}"* 2>/dev/null || true
    swapoff "${disk}"* 2>/dev/null || true
    
    if [[ "$UEFI_MODE" == true ]]; then
        # GPT + EFI + Swap + Root
        sgdisk --zap-all "$disk"
        sgdisk -n 1:0:+512M -t 1:ef00 -c 1:"EFI" "$disk"
        sgdisk -n 2:0:+4G   -t 2:8200 -c 2:"Swap" "$disk"
        sgdisk -n 3:0:0     -t 3:8300 -c 3:"Root" "$disk"
        
        EFI_PART="${disk}1"
        SWAP_PART="${disk}2"
        ROOT_PART="${disk}3"
    else
        # GPT + BIOS boot + Swap + Root
        sgdisk --zap-all "$disk"
        sgdisk -n 1:0:+1M   -t 1:ef02 -c 1:"BIOS Boot" "$disk"
        sgdisk -n 2:0:+4G   -t 2:8200 -c 2:"Swap" "$disk"
        sgdisk -n 3:0:0     -t 3:8300 -c 3:"Root" "$disk"
        
        SWAP_PART="${disk}2"
        ROOT_PART="${disk}3"
    fi
    
    # Esperar a que el kernel reconozca las nuevas particiones
    partprobe "$disk" 2>/dev/null || true
    sleep 2
    
    # ============================================
    # 2. FORMATEO
    # ============================================
    echo "[2/8] Formateando particiones..."
    
    if [[ "$UEFI_MODE" == true ]]; then
        mkfs.fat -F32 "$EFI_PART"
    fi
    
    mkswap "$SWAP_PART"
    mkfs.ext4 -F "$ROOT_PART"
    
    # ============================================
    # 3. MONTAJE
    # ============================================
    echo "[3/8] Montando sistema de archivos..."
    
    mount "$ROOT_PART" /mnt
    swapon "$SWAP_PART"
    
    if [[ "$UEFI_MODE" == true ]]; then
        mkdir -p /mnt/boot/efi
        mount "$EFI_PART" /mnt/boot/efi
    fi
    
    # ============================================
    # 4. PACSTRAP
    # ============================================
    echo "[4/8] Instalando sistema base (pacstrap)..."
    echo "      Esto puede tardar 5-15 minutos..."
    
    # Reflejar mirrors más rápidos
    if command -v reflector &>/dev/null; then
        reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist 2>/dev/null || true
    fi
    
    pacstrap -K /mnt base base-devel linux linux-firmware \
        networkmanager iwd pipewire pipewire-pulse pipewire-alsa wireplumber \
        git curl wget vim nano sudo \
        mesa xf86-video-fbdev xf86-video-vesa \
        efibootmgr grub dosfstools \
        sddm qt6-svg \
        libnewt dialog whiptail \
        2>&1 | tee /tmp/pacstrap.log | while read -r line; do
            echo "  $line"
        done
    
    # Verificar que pacstrap tuvo éxito
    if [[ ! -f /mnt/etc/os-release ]]; then
        echo ""
        echo "❌ ERROR: pacstrap falló. El sistema no se instaló correctamente."
        echo "   Revisa /tmp/pacstrap.log para más detalles."
        exit 1
    fi
    
    # ============================================
    # 5. GENFSTAB
    # ============================================
    echo "[5/8] Generando fstab..."
    genfstab -U /mnt >> /mnt/etc/fstab
    
    # ============================================
    # 6. CONFIGURACIÓN BASE (arch-chroot)
    # ============================================
    echo "[6/8] Configurando sistema base..."
    
    arch-chroot /mnt /bin/bash <<CHROOT_EOF
set -e

# Hostname
echo "$hostname" > /etc/hostname

# Hosts
cat > /etc/hosts <<EOF
127.0.0.1   localhost
127.0.1.1   $hostname
::1         localhost ip6-localhost ip6-loopback
ff02::1     ip6-allnodes
ff02::2     ip6-allrouters
EOF

# Locale
echo "$locale UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=$locale" > /etc/locale.conf

# Keymap y fuente
echo "KEYMAP=$keymap" > /etc/vconsole.conf
echo "FONT=ter-v16n" >> /etc/vconsole.conf

# Zona horaria
ln -sf "/usr/share/zoneinfo/$timezone" /etc/localtime
hwclock --systohc

# Contraseña root
echo "root:$userpass" | chpasswd

# Crear usuario
useradd -m -G wheel,audio,video,storage,optical,network -s /bin/bash "$username" 2>/dev/null || \
useradd -m -G users,audio,video,storage -s /bin/bash "$username"
echo "$username:$userpass" | chpasswd

# Sudo para wheel
echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/10-pi-linux
chmod 440 /etc/sudoers.d/10-pi-linux

# Habilitar servicios esenciales
systemctl enable NetworkManager
systemctl enable sddm

# Initramfs con módulos esenciales para hardware real
mkdir -p /etc/mkinitcpio.conf.d
cat > /etc/mkinitcpio.conf.d/pi-linux.conf <<EOF
MODULES=(nvme vmd thunderbolt xhci_hcd ehci_hcd ohci_hcd usb_storage uas usbhid ahci sd_mod sr_mod)
EOF
mkinitcpio -P

CHROOT_EOF
    
    # ============================================
    # 7. BOOTLOADER
    # ============================================
    echo "[7/8] Instalando bootloader..."
    
    if [[ "$UEFI_MODE" == true ]]; then
        # systemd-boot
        arch-chroot /mnt bootctl install
        
        cat > /mnt/boot/loader/loader.conf <<EOF
default  arch.conf
timeout  4
console-mode max
editor   no
EOF
        
        local root_uuid
        root_uuid=$(blkid -s UUID -o value "$ROOT_PART")
        
        cat > /mnt/boot/loader/entries/arch.conf <<EOF
title   Pi-Linux (Arch)
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=UUID=$root_uuid rw quiet splash
EOF
        
        cat > /mnt/boot/loader/entries/arch-fallback.conf <<EOF
title   Pi-Linux (Fallback)
linux   /vmlinuz-linux
initrd  /initramfs-linux-fallback.img
options root=UUID=$root_uuid rw
EOF
        
        # Safe mode (nomodeset)
        cat > /mnt/boot/loader/entries/arch-safe.conf <<EOF
title   Pi-Linux Safe Mode (nomodeset)
linux   /vmlinuz-linux
initrd  /initramfs-linux-fallback.img
options root=UUID=$root_uuid rw nomodeset
EOF
        
    else
        # GRUB para BIOS
        arch-chroot /mnt grub-install --target=i386-pc --recheck "$disk"
        arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
    fi
    
    # ============================================
    # 8. COPIAR PI-LINUX AL SISTEMA INSTALADO
    # ============================================
    echo "[8/8] Preparando Pi-Linux firstboot..."
    
    # Copiar scripts de Pi-Linux al sistema instalado
    local pi_dest="/mnt/usr/share/pi-linux"
    mkdir -p "$pi_dest"
    
    # Si tenemos los scripts locales (en el live ISO), copiarlos
    if [[ -d "$SCRIPT_DIR" ]]; then
        cp -r "$SCRIPT_DIR"/* "$pi_dest/" 2>/dev/null || true
    fi
    
    # Asegurar que el wrapper existe
    mkdir -p /mnt/usr/local/bin
    cat > /mnt/usr/local/bin/pi-linux-firstboot <<'EOF'
#!/bin/bash
exec bash /usr/share/pi-linux/scripts/pi-linux-firstboot.sh "$@"
EOF
    chmod +x /mnt/usr/local/bin/pi-linux-firstboot
    
    # Instalar y habilitar el servicio de firstboot
    mkdir -p /mnt/etc/systemd/system
    cp "$pi_dest/scripts/pi-linux-firstboot.service" /mnt/etc/systemd/system/ 2>/dev/null || \
    cat > /mnt/etc/systemd/system/pi-linux-firstboot.service <<'SVCEOF'
[Unit]
Description=Pi-Linux First Boot Installer
After=network-online.target
Wants=network-online.target
Before=display-manager.service sddm.service
ConditionPathExists=!/var/lib/pi-linux-installed

[Service]
Type=oneshot
ExecStart=/usr/local/bin/pi-linux-firstboot
StandardInput=tty
StandardOutput=tty
TTYPath=/dev/tty1
TTYReset=yes
TTYVHangup=yes
Restart=on-failure
RestartSec=10
TimeoutStartSec=3600

[Install]
WantedBy=multi-user.target
SVCEOF
    
    # Habilitar el servicio en el sistema instalado
    arch-chroot /mnt systemctl enable pi-linux-firstboot.service
    
    # ============================================
    # DESMONTE Y FIN
    # ============================================
    echo ""
    echo "✅ Instalación de Arch Linux base completada."
    echo ""
    
    # Desmontar
    umount -R /mnt 2>/dev/null || true
    swapoff "$SWAP_PART" 2>/dev/null || true
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  🥧  Pi-Linux está casi listo"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  Al reiniciar, el sistema ejecutará automáticamente"
    echo "  el instalador Pi-Linux para configurar tu escritorio"
    echo "  y rice favorito."
    echo ""
    echo "  • Usuario: $username"
    echo "  • Contraseña: $userpass"
    echo "  • Hostname: $hostname"
    echo ""
    
    if tui_yesno "Reiniciar" "¿Reiniciar ahora para continuar con Pi-Linux?"; then
        echo "Reiniciando en 5 segundos..."
        sleep 5
        reboot
    fi
}

# ============================================
# MAIN
# ============================================

main() {
    check_live
    check_uefi
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "    🥧  Pi-Linux Disk Installer"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Seleccionar disco
    local disks=()
    while IFS= read -r line; do
        disks+=("$line")
    done < <(list_disks)
    
    if [[ ${#disks[@]} -eq 0 ]]; then
        tui_msg "Error" "No se detectaron discos disponibles."
        exit 1
    fi
    
    local menu_args=()
    for d in "${disks[@]}"; do
        local dev size_model
        dev=$(echo "$d" | awk '{print $1}')
        size_model=$(echo "$d" | cut -d' ' -f2-)
        menu_args+=("$dev" "$size_model")
    done
    
    local selected_disk
    selected_disk=$(tui_menu "Seleccionar Disco" "Elige el disco donde instalar Arch Linux:" "${menu_args[@]}")
    
    if [[ -z "$selected_disk" ]]; then
        echo "Cancelado."
        exit 0
    fi
    
    # Configuración básica
    local hostname="pi-linux"
    local username="user"
    local userpass=""
    local timezone="Europe/Madrid"
    local locale="es_ES.UTF-8"
    local keymap="es"
    
    if [[ -n "$TUI" ]]; then
        hostname=$($TUI $ARGS --title "Hostname" --inputbox "Nombre del equipo:" 10 50 "pi-linux" 3>&1 1>&2 2>&3) || hostname="pi-linux"
        username=$($TUI $ARGS --title "Usuario" --inputbox "Nombre de usuario:" 10 50 "user" 3>&1 1>&2 2>&3) || username="user"
        userpass=$($TUI $ARGS --title "Contraseña" --passwordbox "Contraseña para root y $username:" 10 50 3>&1 1>&2 2>&3) || userpass="$username"
        timezone=$($TUI $ARGS --title "Zona Horaria" --inputbox "Zona horaria (ej: Europe/Madrid):" 10 50 "Europe/Madrid" 3>&1 1>&2 2>&3) || timezone="Europe/Madrid"
        locale=$($TUI $ARGS --title "Locale" --inputbox "Locale (ej: es_ES.UTF-8):" 10 50 "es_ES.UTF-8" 3>&1 1>&2 2>&3) || locale="es_ES.UTF-8"
        keymap=$($TUI $ARGS --title "Teclado" --inputbox "Layout de teclado (ej: es, us, latam):" 10 50 "es" 3>&1 1>&2 2>&3) || keymap="es"
    else
        read -rp "Hostname [pi-linux]: " input
        [[ -n "$input" ]] && hostname="$input"
        read -rp "Usuario [user]: " input
        [[ -n "$input" ]] && username="$input"
        read -rsp "Contraseña para root y $username: " userpass
        echo ""
        [[ -z "$userpass" ]] && userpass="$username"
        read -rp "Zona horaria [Europe/Madrid]: " input
        [[ -n "$input" ]] && timezone="$input"
        read -rp "Locale [es_ES.UTF-8]: " input
        [[ -n "$input" ]] && locale="$input"
        read -rp "Teclado [es]: " input
        [[ -n "$input" ]] && keymap="$input"
    fi
    
    # Validar username
    if ! [[ "$username" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
        tui_msg "Error" "Nombre de usuario inválido. Usa solo letras minúsculas, números, guiones y guiones bajos."
        exit 1
    fi
    
    install_to_disk "$selected_disk" "$hostname" "$username" "$userpass" "$timezone" "$locale" "$keymap"
}

main "$@"
