# Pi-Linux Live — Autorun en TTY1
if [[ -z "$DISPLAY" ]] && [[ "$(tty)" == "/dev/tty1" ]]; then
    while true; do
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "    🥧  Pi-Linux Live v$(cat /usr/share/pi-linux/VERSION 2>/dev/null || echo '?')"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "  Este es un entorno live de Arch Linux."
        echo ""
        echo "  Opciones:"
        echo "    1) Ejecutar instalador Pi-Linux TUI"
        echo "    2) Abrir shell"
        echo ""
        read -rp "  Selecciona [1/2]: " choice
        case "$choice" in
            1)
                if [[ -f /usr/share/pi-linux/scripts/tui.sh ]]; then
                    bash /usr/share/pi-linux/scripts/tui.sh
                    echo ""
                    read -rp "  Presiona Enter para volver al menú..."
                else
                    echo "  ❌ Instalador no encontrado."
                    read -rp "  Presiona Enter para continuar..."
                fi
                ;;
            2)
                echo "  Abriendo shell..."
                break
                ;;
            *)
                echo "  Opción inválida."
                ;;
        esac
    done
fi
