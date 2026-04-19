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
        echo "  ⚠️  Este es un entorno LIVE (en memoria RAM)."
        echo "      Todo lo que instales aquí se perderá al reiniciar."
        echo ""
        echo "  Para instalar Pi-Linux en tu disco duro:"
        echo "    1) Instala Arch Linux base con 'archinstall'"
        echo "    2) Reinicia al sistema instalado"
        echo "    3) Pi-Linux se personalizará automáticamente"
        echo ""
        echo "  Opciones:"
        echo "    1) Ejecutar archinstall (instalar Arch en disco)"
        echo "    2) Abrir shell"
        echo ""
        read -rp "  Selecciona [1/2]: " choice
        case "$choice" in
            1)
                if command -v archinstall &>/dev/null; then
                    archinstall
                    echo ""
                    echo "  ✅ Cuando archinstall termine, reinicia:"
                    echo "       systemctl reboot"
                else
                    echo "  ❌ archinstall no encontrado."
                fi
                echo ""
                read -rp "  Presiona Enter para continuar..."
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
