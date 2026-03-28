#!/bin/bash
# distro/arch/arch.sh — Instalação para Arch Linux
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${RC}  $1"; }
success() { echo -e "${GREEN}[OK]${RC}    $1"; }
warn()    { echo -e "${YELLOW}[WARN]${RC}  $1"; }
error()   { echo -e "${RED}[ERRO]${RC}  $1"; }
step()    { echo -e "\n${CYAN}${BOLD}==> $1${RC}"; }

REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(eval echo "~$REAL_USER")

install_aur_helper() {
    step "Instalando AUR helper"

    if command -v yay &>/dev/null; then
        success "yay já instalado"
        AUR_HELPER="yay"
        return
    fi

    if command -v paru &>/dev/null; then
        success "paru já instalado"
        AUR_HELPER="paru"
        return
    fi

    echo -e "  ${CYAN}1)${RC} yay"
    echo -e "  ${CYAN}2)${RC} paru"
    echo -ne "  ${YELLOW}Escolha o AUR helper [1/2]:${RC} "
    read -r aur_choice < /dev/tty

    cd /tmp
    case "$aur_choice" in
        2)
            AUR_HELPER="paru"
            sudo -u "$REAL_USER" git clone https://aur.archlinux.org/paru.git /tmp/paru_build
            cd /tmp/paru_build
            sudo -u "$REAL_USER" makepkg -si --noconfirm
            ;;
        *)
            AUR_HELPER="yay"
            sudo -u "$REAL_USER" git clone https://aur.archlinux.org/yay.git /tmp/yay_build
            cd /tmp/yay_build
            sudo -u "$REAL_USER" makepkg -si --noconfirm
            ;;
    esac

    success "$AUR_HELPER instalado"
}

install_base_deps() {
    step "Atualizando sistema e instalando dependências base"

    pacman -Syu --noconfirm

    local BASE_PKGS=(
        hyprland
        xdg-desktop-portal-hyprland
        xdg-desktop-portal-gtk
        wayland
        wlroots
        sddm
        qt5-declarative
        qt5-graphicaleffects
        qt5-quickcontrols2
        pipewire
        pipewire-alsa
        pipewire-pulse
        wireplumber
        base-devel
        git
        curl
        wget
    )

    pacman -S --noconfirm --needed "${BASE_PKGS[@]}"
    success "Dependências base instaladas"
}

install_env_packages() {
    step "Instalando pacotes do ambiente"

    local ENV_PKGS=(
        waybar
        rofi-wayland   # Terminal
        alacritty
        kitty
        dunst
        libnotify
        swww
        hyprlock
        hypridle
        hyprshot
        grim
        slurp
        wl-clipboard
        cliphist
        brightnessctl
        playerctl
        pamixer
        thunar
        gvfs
        thunar-archive-plugin
        file-roller
        nwg-look
        gtk3
        gtk4
        papirus-icon-theme
        ttf-jetbrains-mono-nerd
        ttf-nerd-fonts-symbols
        noto-fonts-emoji
        btop
        fastfetch
        polkit-kde-agent
        xdg-utils
        xdg-user-dirs
        python
        python-pip
    )

    pacman -S --noconfirm --needed "${ENV_PKGS[@]}"
    success "Pacotes do ambiente instalados"
}

install_aur_packages() {
    step "Instalando pacotes do AUR"

    local AUR_PKGS=(
        hyprpaper
        hyprshot
        wlogout
        swayosd-git
    )

    sudo -u "$REAL_USER" "$AUR_HELPER" -S --noconfirm --needed "${AUR_PKGS[@]}" || \
        warn "Alguns pacotes AUR falharam — verifique manualmente"

    success "Pacotes AUR instalados"
}

enable_services() {
    step "Habilitando serviços"

    systemctl enable sddm
    success "SDDM habilitado"

    sudo -u "$REAL_USER" systemctl --user enable pipewire pipewire-pulse wireplumber 2>/dev/null || true
    success "PipeWire habilitado"
}

copy_dotfiles() {
    step "Copiando dotfiles para ~/.config"

    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    DOTS_DIR="$SCRIPT_DIR/../../dots"

    if [ ! -d "$DOTS_DIR" ]; then
        warn "Diretório de dotfiles não encontrado em: $DOTS_DIR"
        warn "Pulando cópia de configs. Adicione seus configs em distro/arch/../../dots/"
        return
    fi

    mkdir -p "$REAL_HOME/.config"

    for dir in "$DOTS_DIR"/*/; do
        app=$(basename "$dir")
        dest="$REAL_HOME/.config/$app"

        if [ -d "$dest" ]; then
            warn "Backup de config existente: $dest → $dest.bak"
            mv "$dest" "${dest}.bak"
        fi

        cp -r "$dir" "$dest"
        chown -R "$REAL_USER:$REAL_USER" "$dest"
        success "Config copiado: ~/.config/$app"
    done
}

configure_monitor_hint() {
    step "Verificando monitor"

    local monitors
    monitors=$(hyprctl monitors 2>/dev/null | grep "Monitor" | awk '{print $2}' || echo "")

    if [ -n "$monitors" ]; then
        info "Monitor(es) detectado(s): ${YELLOW}$monitors${RC}"
        warn "O waybar usa nomes de monitor fixos."
        warn "Edite ${CYAN}~/.config/waybar/config${RC} e ajuste o campo ${CYAN}\"output\"${RC} se necessário."
    else
        warn "Hyprland ainda não iniciou. Após o reboot, rode:"
        warn "  ${CYAN}hyprctl monitors${RC}"
        warn "E ajuste o campo 'output' em ~/.config/waybar/config"
    fi
}

main() {
    install_base_deps
    install_aur_helper
    install_env_packages
    install_aur_packages
    copy_dotfiles
    enable_services
    configure_monitor_hint

    echo ""
    echo -e "${GREEN}${BOLD}"
    echo "  ╔══════════════════════════════════════════════════╗"
    echo "  ║  Arch: instalação concluída!                     ║"
    echo "  ║  → Reinicie e selecione Hyprland no SDDM         ║"
    echo "  ╚══════════════════════════════════════════════════╝"
    echo -e "${RC}"
}

main