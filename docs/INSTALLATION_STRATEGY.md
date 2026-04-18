# 📍 Estrategias de Integración del TUI en la Instalación de Arch Linux

## Pregunta: ¿Dónde lanzar el TUI de Pi-Linux?

Hay **3 enfoques válidos**, cada uno con sus pros y contras:

---

## Estrategia 1: ISO Live con Autorun (✅ YA IMPLEMENTADA)

**Cómo funciona:**
1. Arrancas la ISO de Pi-Linux desde USB
2. Autologin en `tty1` como `root`
3. El instalador se lanza **automáticamente**
4. Seleccionas DE, rice, usuario, etc.
5. Se instala TODO en el disco destino
6. Reboot y listo

**Ventajas:**
- ✅ Experiencia "instalador completo" al estilo Ubuntu/Calamares
- ✅ El usuario no necesita saber instalar Arch manualmente
- ✅ Ideal para distribución a terceros
- ✅ Todo el proceso es visual y guiado

**Desventajas:**
- ❌ La ISO es grande (~2-3GB)
- ❌ No permite personalizar la partición con fines específicos
- ❌ Más trabajo de mantenimiento del perfil archiso

**Ideal para:** Usuarios que quieren instalar Arch sin saber los pasos manuales.

---

## Estrategia 2: Primer Boot del Sistema Instalado (🔧 RECOMENDADA)

**Cómo funciona:**
1. Instalas Arch Linux manualmente (o con `archinstall`)
2. Al primer boot del sistema instalado, aparece el TUI de Pi-Linux
3. Se ejecuta **una sola vez** y se autodestruye
4. Instala el DE, rice, software, etc.
5. Reboot y listo

**Implementación técnica:**
```systemd
# /etc/systemd/system/pi-linux-firstboot.service
[Unit]
Description=Pi-Linux First Boot Installer
After=network-online.target
Wants=network-online.target
ConditionPathExists=!/var/lib/pi-linux-installed

[Service]
Type=oneshot
ExecStart=/usr/local/bin/pi-linux-firstboot
RemainAfterExit=yes
StandardInput=tty
StandardOutput=tty
TTYPath=/dev/tty1
TTYReset=yes
TTYVHangup=yes

[Install]
WantedBy=multi-user.target
```

**Ventajas:**
- ✅ Permite hacer una instalación base de Arch normal (particiones personalizadas, LUKS, etc.)
- ✅ El usuario tiene control total sobre la base
- ✅ Pi-Linux solo se encarga del "post-instalación"
- ✅ Más ligero (no necesitas ISO enorme)

**Desventajas:**
- ❌ Requiere dos reboots (instalación base + configuración Pi-Linux)
- ❌ El usuario necesita saber instalar Arch base primero

**Ideal para:** Usuarios avanzados que quieren controlar la base pero no configurar el escritorio manualmente.

---

## Estrategia 3: Post-Instalación Manual (📦 MÁS SIMPLE)

**Cómo funciona:**
1. Instalas Arch Linux manualmente
2. Reinicias, logueas como usuario
3. Ejecutas el one-liner de Pi-Linux:
   ```bash
   bash <(curl -sL https://raw.githubusercontent.com/Pinedux/pi-linux/main/scripts/tui.sh)
   ```
4. Se instala todo

**Ventajas:**
- ✅ Mínimo esfuerzo de desarrollo
- ✅ No requiere ISO ni servicios systemd
- ✅ El usuario controla exactamente cuándo ejecutarlo

**Desventajas:**
- ❌ Requiere conexión a internet en el sistema instalado
- ❌ El usuario necesita saber/recordar el comando

**Ideal para:** Usuarios que ya tienen Arch instalado y quieren "ricearlo".

---

## 🏆 Recomendación Final

### Para distribución general → **Estrategia 1 (ISO Live)**
Es la más amigable. El usuario mete el USB, arranca, y en 20 minutos tiene Arch + DE + Rice + Software.

### Para usuarios avanzados → **Estrategia 2 (First Boot)**
Permite cifrar discos, RAID, LVM, particiones custom, etc. y luego aplicar Pi-Linux automáticamente.

### Para uso personal → **Estrategia 3 (One-liner)**
El más simple. Instalas Arch como siempre y luego ejecutas un comando.

---

## Diagrama Comparativo

```
┌─────────────────────────────────────────────────────────────────────┐
│                    ESTRATEGIA 1: ISO LIVE                           │
│                                                                     │
│   USB ──→ Boot ──→ TUI Auto ──→ Instala TODO ──→ Reboot ──→ 🎉     │
│                                                                     │
│   Tiempo total: ~20-30 min  |  Conocimiento requerido: Mínimo      │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                 ESTRATEGIA 2: FIRST BOOT                            │
│                                                                     │
│   Instalar Arch ──→ Reboot ──→ TUI Auto ──→ Instala DE ──→ 🎉      │
│   (manualmente)         (primer boot)                               │
│                                                                     │
│   Tiempo total: ~30-45 min  |  Conocimiento requerido: Medio       │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│              ESTRATEGIA 3: POST-INSTALACIÓN                         │
│                                                                     │
│   Instalar Arch ──→ Reboot ──→ Login ──→ curl | bash ──→ 🎉        │
│   (manualmente)                       (one-liner)                   │
│                                                                     │
│   Tiempo total: ~30-45 min  |  Conocimiento requerido: Medio       │
└─────────────────────────────────────────────────────────────────────┘
```

---

## ¿Dónde colocar el TUI en la guía oficial de Arch?

En la [guía de instalación de Arch](https://wiki.archlinux.org/title/Installation_guide), el TUI de Pi-Linux debería ir **después del paso "Reboot"** (o como servicio en el primer boot):

```
1. Preparación
2. Particionar, formatear, montar
3. pacstrap (instalar base)
4. arch-chroot /mnt
5. Configurar: fstab, timezone, locale, hostname
6. Crear usuario
7. Instalar bootloader (GRUB/systemd-boot)
8. Salir del chroot, desmontar
9. reboot
10. 🥧 PI-LINUX TUI APARECE AQUÍ (Estrategia 2)
    o
10. Login como usuario
11. bash <(curl ...)  (Estrategia 3)
```

**No se recomienda ejecutar Pi-Linux DENTRO del `arch-chroot`** porque:
- Algunos servicios (SDDM, NetworkManager) no pueden habilitarse correctamente sin systemd corriendo
- Los dotfiles se crearían en `/mnt/home/usuario` pero con permisos potencialmente incorrectos
- El entorno chroot no tiene acceso completo a hardware (GPU detection puede fallar)
