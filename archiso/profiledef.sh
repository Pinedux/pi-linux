#!/usr/bin/env bash
# shellcheck disable=SC2034

iso_name="pi-linux"
iso_label="PI_LINUX_$(date +%Y%m)"
iso_publisher="Pi Linux Project <https://github.com/Pinedux/pi-linux>"
iso_application="Pi-Linux Live/Installer"
iso_version="2.0.0"
install_dir="pilinux"
buildmodes=('iso')
bootmodes=('bios.syslinux'
           'uefi.systemd-boot')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'zstd' '-Xcompression-level' '15' '-b' '1M')
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/etc/gshadow"]="0:0:400"
  ["/usr/local/bin/pi-linux-installer"]="0:0:755"
)
