# 🥧 Pi-Linux

[![Arch Linux](https://img.shields.io/badge/Arch%20Linux-1793D1?logo=arch-linux&logoColor=fff&style=flat)](https://archlinux.org)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Shell](https://img.shields.io/badge/Shell-Bash-4EAA25?logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)

> Instalador automático e interactivo para Arch Linux. Transforma tu instalación base de Arch en un sistema completo y productivo con un solo comando.

![Pi-Linux Screenshot](assets/screenshot.png)

## ✨ Características

- 🚀 **Instalación con un solo comando** - Estilo Xero Linux
- 🎨 **3 Entornos de Escritorio** - KDE Plasma, GNOME, Hyprland
- 🖥️ **Detección automática de GPU** - NVIDIA, AMD, Intel
- ⚡ **Herramientas CLI modernas** - fzf, ripgrep, zoxide, eza, bat
- 🎭 **Temas populares** - WhiteSur, Sweet, Dracula, Orchis
- 📝 **Dotfiles listos** - Hyprland preconfigurado
- 🔧 **100% Personalizable** - Código abierto y modular

## 🚀 Instalación Rápida

### Método 1: One-Liner (Recomendado)

```bash
curl -fsSL https://raw.githubusercontent.com/Pinedux/pi-linux/main/install.sh | sudo bash
```

### Método 2: Clonar Repositorio

```bash
git clone https://github.com/Pinedux/pi-linux.git
cd pi-linux
sudo ./pi-linux.sh
```

### Método 3: Descargar y Ejecutar

```bash
wget https://github.com/Pinedux/pi-linux/archive/main.tar.gz
tar -xzf main.tar.gz
cd pi-linux-main
sudo ./pi-linux.sh
```

## 📋 Requisitos

- Arch Linux instalado (post-base-installation)
- Conexión a internet
- Ejecutar como root (sudo)
- ~10GB de espacio libre

## 🖥️ Entornos de Escritorio Soportados

| Entorno | Descripción | Estado |
|---------|-------------|--------|
| **KDE Plasma** | Moderno, customizable, rico en features | ✅ Completo |
| **GNOME** | Limpio, minimalista, profesional | ✅ Completo |
| **Hyprland** | Tiling Wayland con animaciones | ✅ Completo |

## 🎨 Temas Incluidos

### KDE Plasma
- 🍎 **WhiteSur** - Estilo macOS
- 🍬 **Sweet** - Colorido y moderno  
- 🧛 **Dracula** - Oscuro y elegante

### GNOME
- 🍎 **WhiteSur** - Estilo macOS
- 🌸 **Orchis** - Material Design
- ⬛ **Graphite** - Minimalista oscuro

## 🛠️ Software Incluido

### Navegadores
- Firefox, Google Chrome, Brave

### Productividad
- VS Code, Obsidian, OnlyOffice

### Terminal & CLI
- `kitty`, `alacritty`
- `fzf` - Fuzzy finder
- `ripgrep` - Búsqueda ultrarrápida
- `fd` - Alternativa moderna a find
- `bat` - Cat con syntax highlighting
- `eza` - ls con iconos y mejoras
- `zoxide` - cd inteligente con aprendizaje
- `atuin` - Historial de comandos con sync

### Editores
- `neovim`, `lazyvim`, `doomemacs`

### Shells
- `zsh` + Oh-My-Zsh
- `fish` + Oh-My-Fish
- `starship` - Prompt minimalista

### Monitores
- `btop` - Recursos del sistema
- `nvtop` - GPU (NVIDIA/AMD)

## 📖 Uso

### Modo Interactivo (Recomendado)

```bash
sudo ./pi-linux.sh
```

Te guiará paso a paso:
1. Selecciona Entorno de Escritorio
2. Confirma/Selecciona GPU
3. Elige tema visual
4. Selecciona software adicional

### Modo Automático

```bash
sudo ./pi-linux.sh --unattended
```

Instala KDE Plasma con configuración por defecto.

### Modo GUI (Whiptail)

```bash
sudo ./pi-linux.sh --gui
```

Interfaz gráfica en terminal (si está disponible).

## ⚙️ Configuración Desatendida

Edita `config/unattended.conf`:

```bash
# Entorno: plasma, gnome, hyprland
DESKTOP_ENV="plasma"

# GPU: auto, nvidia, amd, intel
GPU_TYPE="auto"

# Tema: whitesur, sweet, dracula, orchis, graphite, none
THEME="whitesur"

# Software (y/n)
INSTALL_CHROME="y"
INSTALL_VSCODE="y"
INSTALL_NEOVIM="y"
```

Luego ejecuta:
```bash
sudo ./pi-linux.sh --unattended
```

## 🏗️ Estructura del Proyecto

```
pi-linux/
├── install.sh           # Entry point para curl
├── pi-linux.sh          # Script principal
├── modules/
│   ├── 00-preinstall.sh # Actualización y preparación
│   ├── 01-base.sh       # Sistema base
│   ├── 02-gpu.sh        # Drivers GPU
│   ├── 03-desktop.sh    # Entorno de escritorio
│   ├── 04-themes.sh     # Temas visuales
│   ├── 05-software.sh   # Software adicional
│   └── 06-dotfiles.sh   # Dotfiles Hyprland
├── config/
│   └── unattended.conf  # Configuración modo automático
├── scripts/
│   └── gui.sh           # Interfaz gráfica whiptail
└── README.md
```

## 🤝 Contribuir

1. Fork el repositorio
2. Crea una rama: `git checkout -b feature/nueva-feature`
3. Commit: `git commit -am 'Agregar nueva feature'`
4. Push: `git push origin feature/nueva-feature`
5. Abre un Pull Request

### Ideas de Contribución

- [ ] Más entornos de escritorio (XFCE, Cinnamon, i3, Sway)
- [ ] Más temas visuales
- [ ] Soporte para más GPUs
- [ ] Internacionalización (i18n)
- [ ] Tests automatizados
- [ ] Wiki con documentación

## 🐛 Solución de Problemas

### Error: "No such file or directory"
```bash
# Asegúrate de tener bash instalado
pacman -S bash
```

### Error de permisos
```bash
# Ejecutar siempre como root
sudo ./pi-linux.sh
```

### Fallo en descarga
```bash
# Verificar conexión y reintentar
ping -c 3 github.com
curl -fsSL ... | sudo bash
```

## 📜 Licencia

MIT License - Ver [LICENSE](LICENSE)

## 🙏 Agradecimientos

- Inspirado en [Xero Linux](https://xerolinux.xyz/)
- Comunidad de Arch Linux
- Creadores de temas y herramientas incluidas

## 📞 Contacto

- GitHub Issues: [github.com/Pinedux/pi-linux/issues](https://github.com/Pinedux/pi-linux/issues)
- Discord: [Tu servidor de Discord]

---

**Hecho con ❤️ para la comunidad Linux**
