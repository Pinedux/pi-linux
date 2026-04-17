# Pi-Linux 🥧

Instalador automático e interactivo para **Arch Linux** con **rices completos** listos para usar.

Transforma una instalación base de Arch (solo CLI) en un sistema de escritorio completamente tematizado con un solo comando.

---

## ✨ Características

- 🚀 **Rices Automáticos** — No solo instala paquetes, instala **experiencias completas**
- 🎨 **SDDM Unificado** — Tema moderno (`sddm-astronaut-theme`) para todos los entornos
- 🎮 **Hyprland + HyDE** — Instalación automática del rice más popular de Hyprland (recomendado oficialmente)
- 🍎 **GNOME + WhiteSur** — macOS-like completo con extensions esenciales
- 💜 **Plasma + Sweet** — Moderno oscuro con acentos vibrantes
- 🖥️ **Detección automática de GPU** — NVIDIA, AMD, Intel
- ⚡ **Software CLI productivo** — fzf, ripgrep, zoxide, atuin y más
- 📝 **Modo desatendido** — Instalación 100% automática vía `config/unattended.conf`

---

## 📋 Requisitos

- Arch Linux base instalado (solo CLI)
- Conexión a internet
- Ejecutar como `root`

---

## 🚀 Uso Rápido

```bash
# 1. Entrar al directorio
cd ~/www/pi_linux

# 2. Hacer ejecutable
chmod +x pi-linux.sh

# 3. Ejecutar (modo interactivo)
sudo ./pi-linux.sh

# O modo automático/desatendido
sudo ./pi-linux.sh --unattended
```

---

## 📁 Estructura del Proyecto

```
pi_linux/
├── pi-linux.sh              # Script principal (menú interactivo)
├── lib/
│   └── pi-linux-common.sh   # Funciones helper compartidas
├── modules/
│   ├── 00-preinstall.sh     # Actualizar sistema
│   ├── 01-base.sh           # Sistema base
│   ├── 02-sddm.sh           # SDDM unificado + tema astronaut
│   ├── 02-gpu.sh            # Drivers GPU (NVIDIA/AMD/Intel)
│   ├── 03-desktop.sh        # Entorno de escritorio
│   ├── 04-themes.sh         # Rice completo por DE
│   ├── 04-software.sh       # Software esencial
│   ├── 05-software.sh       # Herramientas CLI, shells, editores
│   └── 06-hyprland-rice.sh  # HyDE / ML4W / end-4 automático
├── config/
│   └── unattended.conf      # Configuración modo automático
└── deploy-pi-linux.sh       # Script para desplegar todo desde cero
```

---

## 🖥️ Entornos de Escritorio y Rices

### 🏴‍☠️ Hyprland
| Rice | Descripción | Estrellas | Instalador |
|------|-------------|-----------|------------|
| **HyDE** | Recomendado oficial por Hyprland. Waybar, Rofi, Kitty, temas dinámicos. | ~9k⭐ | ✅ Automático |
| **ML4W** | My Linux For Work. Amigable para principiantes, GUI settings. | ~4.6k⭐ | ✅ Automático |
| **end-4** | Illogical Impulse. Visualmente impresionante con Quickshell. | ~14k⭐ | ✅ Automático |

### 🍎 GNOME
| Rice | Descripción | Incluye |
|------|-------------|---------|
| **WhiteSur** | macOS Big Sur/Monterey completo | GTK + Shell + Icons + Cursor |
| **Orchis** | Material Design refinado | GTK + Shell + Tela Icons |
| **Graphite** | Flat minimalista oscuro | GTK + Shell + Nord variantes |
| **Catppuccin** | Pastel developer-friendly | GTK + Icons |
| **Nordic** | Paleta Nord azul | GTK + Shell |

### 💜 KDE Plasma 6
| Rice | Descripción | Incluye |
|------|-------------|---------|
| **Sweet** | Moderno oscuro con acentos rosas | Global Theme + Kvantum + Aurorae |
| **WhiteSur** | macOS completo | Global Theme + Kvantum + SDDM |
| **MacTahoe** | macOS Tahoe más reciente | Global Theme + Kvantum |
| **Layan** | Material púrpura | Global Theme + Kvantum + Tela Icons |
| **Catppuccin** | Pastel 4 sabores | Global Theme + Kvantum + Icons |
| **Orchis** | Material redondeado | Global Theme + Kvantum + Tela Icons |

---

## ⚙️ Modo Desatendido

Edita `config/unattended.conf` antes de ejecutar:

```bash
# Personalizar configuración
nano config/unattended.conf

# Ejecutar modo automático
sudo ./pi-linux.sh --unattended
```

### Variables principales

| Variable | Opciones | Descripción |
|----------|----------|-------------|
| `DESKTOP_ENV` | `plasma`, `gnome`, `hyprland` | Entorno de escritorio |
| `HYPR_RICE` | `hyde`, `ml4w`, `end4`, `none` | Rice para Hyprland |
| `GNOME_RICE` | `whitesur`, `orchis`, `graphite`, `catppuccin`, `nordic`, `none` | Rice para GNOME |
| `PLASMA_RICE` | `whitesur`, `mactahoe`, `sweet`, `layan`, `catppuccin`, `orchis`, `none` | Rice para Plasma |
| `GPU_TYPE` | `auto`, `nvidia`, `amd`, `intel`, `vm` | Driver GPU |
| `SDDM_THEME` | `astronaut`, `elegant`, `match-de` | Tema del login |
| `INSTALL_GNOME_EXTENSIONS` | `y`, `n` | Instalar extensions GNOME |

---

## 🛠️ Post-Instalación

Después de instalar:

```bash
# Reiniciar
reboot

# Iniciar sesión en SDDM y disfrutar tu rice!
```

---

## 🎯 SDDM — Display Manager Unificado

Todos los entornos usan **SDDM** con tema moderno:

- **Plasma**: SDDM nativo, tema emparejado al rice (Sweet, WhiteSur, etc.)
- **GNOME**: SDDM en lugar de GDM, para consistencia y personalización
- **Hyprland**: SDDM con `sddm-astronaut-theme` (moderno, minimal, con variantes)

---

## 📝 Personalización

### Agregar paquetes personalizados

Edita el módulo correspondiente en `modules/`:

```bash
# Ejemplo: agregar paquete al módulo base
nano modules/01-base.sh

# Agregar a la lista de pacman -S
pacman -S --needed --noconfirm tu-paquete
```

### Crear tu propio rice

Puedes añadir nuevos rices editando `modules/04-themes.sh` y añadiendo una función:

```bash
install_mi_tema() {
    # Tus comandos de instalación aquí
}
```

---

## 🐛 Solución de Problemas

### Error de permisos
```bash
# Asegúrate de ejecutar como root
sudo ./pi-linux.sh
```

### Fallo en módulo específico
```bash
# Puedes ejecutar módulos individualmente
sudo bash modules/02-sddm.sh
sudo bash modules/04-themes.sh
```

### Ver log de instalación
```bash
cat /tmp/pi-linux-*.log | tail -n 100
```

### HyDE no se instala correctamente
HyDE requiere conexión a internet y puede pedir confirmación en su instalador. Si falla, instálalo manualmente después:

```bash
git clone --depth 1 https://github.com/HyDE-Project/HyDE ~/HyDE
cd ~/HyDE/Scripts
./install.sh
```

---

## 🤝 Contribuir

¡Las contribuciones son bienvenidas!

1. Fork el proyecto
2. Crea una rama (`git checkout -b feature/nueva-caracteristica`)
3. Commit tus cambios (`git commit -am 'Agregar nueva característica'`)
4. Push a la rama (`git push origin feature/nueva-caracteristica`)
5. Abre un Pull Request

---

## 📄 Licencia

MIT License — Libre para usar y modificar

## 🙏 Agradecimientos

- [HyDE-Project](https://github.com/HyDE-Project/HyDE) — Rice oficial de Hyprland
- [vinceliuice](https://github.com/vinceliuice) — WhiteSur, Orchis, Layan, MacTahoe themes
- [EliverLara](https://github.com/EliverLara) — Sweet, Nordic themes
- [Catppuccin](https://github.com/catppuccin) — Paleta pastel para developers
- [Keyitdev](https://github.com/Keyitdev/sddm-astronaut-theme) — SDDM Astronaut Theme
- Comunidad de Arch Linux

---

## 🌐 Instalación vía curl (one-liner)

Una vez subido a GitHub, podrás instalar Pi-Linux directamente con:

```bash
bash <(curl -sL https://raw.githubusercontent.com/TU_USUARIO/pi-linux/main/pi-linux.sh)
```

O el modo TUI:

```bash
bash <(curl -sL https://raw.githubusercontent.com/TU_USUARIO/pi-linux/main/scripts/tui.sh)
```

> **Nota:** Reemplaza `TU_USUARIO` con tu usuario de GitHub antes de usar.

---

## 💿 Crear ISO Live con Pi-Linux

Pi-Linux incluye un perfil de **archiso** para generar una ISO live que arranca directamente en el instalador TUI.

### Requisitos

```bash
sudo pacman -S archiso qemu-desktop
```

### Compilar la ISO

```bash
cd ~/www/pi_linux
sudo ./build-iso.sh build
```

La ISO se generará en `iso-output/`.

### Probar la ISO

```bash
# Modo BIOS
sudo ./build-iso.sh test

# Modo UEFI
run_archiso -u -i iso-output/pi-linux-*.iso
```

### Grabar en USB

```bash
sudo dd if=iso-output/pi-linux-*.iso of=/dev/sdX bs=4M status=progress
```

### ¿Qué incluye la ISO?

- ✅ Arch Linux live con kernel LTS
- ✅ Autologin en `tty1` como root
- ✅ TUI de Pi-Linux arranca automáticamente
- ✅ Drivers GPU (NVIDIA, AMD, Intel)
- ✅ Entornos de escritorio pre-descargados (Plasma, GNOME, Hyprland)
- ✅ Conexión de red automática via NetworkManager
- ✅ Clona el repo desde GitHub y ejecuta el instalador

---

## 📤 Subir a GitHub

Si aún no has configurado el remote:

```bash
# 1. Crear repo en GitHub (vacío, sin README)
# 2. En tu terminal:
cd ~/www/pi_linux
git remote add origin https://github.com/TU_USUARIO/pi-linux.git
git branch -M main
git push -u origin main
```

Para actualizar después de cambios:

```bash
git add -A
git commit -m "feat: descripción del cambio"
git push
```

---

**Hecho con ❤️ para la comunidad Linux**
