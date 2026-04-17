# Pi-Linux Live Installer — Autorun en TTY1
if [[ -z "$DISPLAY" ]] && [[ "$(tty)" == "/dev/tty1" ]]; then
    clear
    /usr/local/bin/pi-linux-installer || bash
fi
