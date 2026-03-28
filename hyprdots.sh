#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/hyprdots_install.log"

log() { echo -e "$1" | tee -a "$LOG_FILE"; }
info()    { log "${BLUE}[INFO]${RC}  $1"; }
success() { log "${GREEN}[OK]${RC}    $1"; }
warn()    { log "${YELLOW}[WARN]${RC}  $1"; }
error()   { log "${RED}[ERRO]${RC}  $1"; }
step()    { log "${CYAN}${BOLD}==> $1${RC}"; }

banner() {
    clear
    echo -e "${BLUE}${BOLD}"
    echo "  ██╗  ██╗██╗   ██╗██████╗ ██████╗ ██████╗  ██████╗ ████████╗███████╗"
    echo "  ██║  ██║╚██╗ ██╔╝██╔══██╗██╔══██╗██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝"
    echo "  ███████║ ╚████╔╝ ██████╔╝██████╔╝██║  ██║██║   ██║   ██║   ███████╗"
    echo "  ██╔══██║  ╚██╔╝  ██╔═══╝ ██╔══██╗██║  ██║██║   ██║   ██║   ╚════██║"
    echo "  ██║  ██║   ██║   ██║     ██║  ██║██████╔╝╚██████╔╝   ██║   ███████║"
    echo "  ╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚═╝  ╚═╝╚═════╝  ╚═════╝    ╚═╝   ╚══════╝"
    echo -e "${RC}"
    echo -e "  ${CYAN}csouzape/hyprdots${RC} — Arch Linux · Hyprland"
    echo -e "  ${YELLOW}Log:${RC} $LOG_FILE"
    echo ""
}

detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    elif [ -f /etc/arch-release ]; then
        echo "arch"
    else
        echo "unknown"
    fi
}

detect_ides() {
    IDES_FOUND=()

    if command -v code &>/dev/null || command -v codium &>/dev/null; then
        IDES_FOUND+=("vscode")
    fi

    if command -v nvim &>/dev/null; then
        IDES_FOUND+=("neovim")
    fi
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        error "Execute com sudo: ${BOLD}sudo ./hyprdots.sh${RC}"
        exit 1
    fi
}

check_script() {
    local script_path="$1"
    if [ ! -f "$script_path" ]; then
        error "Script não encontrado: $script_path"
        exit 1
    fi
    chmod +x "$script_path"
}

run_install() {
    local DISTRO
    DISTRO=$(detect_distro)
    info "Distribuição detectada: ${YELLOW}${DISTRO}${RC}"
    echo ""

    case "$DISTRO" in
        arch|archarm|manjaro|endeavouros)
            INSTALL_SCRIPT="$SCRIPT_DIR/distro/arch/arch.sh"
            success "Usando script de instalação para Arch Linux"
            ;;
        *)
            error "Distribuição não suportada: $DISTRO"
            warn "Suportado: Arch Linux e variantes"
            exit 1
            ;;
    esac

    check_script "$INSTALL_SCRIPT"

    step "Iniciando instalação..."
    echo ""
    bash "$INSTALL_SCRIPT" < /dev/tty

    echo ""
    echo -e "${GREEN}${BOLD}"
    echo "  ╔══════════════════════════════════════╗"
    echo "  ║   Instalação concluída com sucesso!  ║"
    echo "  ╚══════════════════════════════════════╝"
    echo -e "${RC}"
    warn "Reinicie o sistema para iniciar o Hyprland."
}


HYPR_PACKAGES=(
    hyprland hyprpaper hyprlock hypridle hyprshot xdg-desktop-portal-hyprland
    waybar rofi-wayland alacritty kitty dunst swww
    pipewire pipewire-alsa pipewire-pulse wireplumber
    sddm qt5-declarative qt5-graphicaleffects qt5-quickcontrols2
    nwg-look gtk4 gtk3 papirus-icon-theme
    thunar gvfs thunar-archive-plugin file-roller
    brightnessctl playerctl pamixer
    wl-clipboard cliphist grim slurp
    polkit-kde-agent xdg-utils xdg-user-dirs
    ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols noto-fonts-emoji
    btop fastfetch
)

VSCODE_PROTECTED=(code code-oss vscodium visual-studio-code-bin)
NEOVIM_PROTECTED=(neovim nvim)

build_removal_list() {
    detect_ides
    REMOVAL_LIST=("${HYPR_PACKAGES[@]}")

    if [[ " ${IDES_FOUND[*]} " =~ "vscode" ]]; then
        warn "VS Code/VSCodium detectado → configs e pacote preservados"
        for pkg in "${VSCODE_PROTECTED[@]}"; do
            REMOVAL_LIST=("${REMOVAL_LIST[@]/$pkg}")
        done
    fi

    if [[ " ${IDES_FOUND[*]} " =~ "neovim" ]]; then
        warn "Neovim detectado → configs e pacote preservados"
        for pkg in "${NEOVIM_PROTECTED[@]}"; do
            REMOVAL_LIST=("${REMOVAL_LIST[@]/$pkg}")
        done
    fi

    # Remove entradas vazias
    REMOVAL_LIST=("${REMOVAL_LIST[@]// /}")
    REMOVAL_LIST=("${REMOVAL_LIST[@]//^$/}")
}

remove_dotfiles() {
    step "Removendo dotfiles linkados..."

    local configs=(
        "$HOME/.config/hypr"
        "$HOME/.config/waybar"
        "$HOME/.config/rofi"
        "$HOME/.config/alacritty"
        "$HOME/.config/dunst"
        "$HOME/.config/swww"
    )

    for cfg in "${configs[@]}"; do
        if [ -d "$cfg" ] || [ -L "$cfg" ]; then
            rm -rf "$cfg"
            success "Removido: $cfg"
        fi
    done
}

remove_packages() {
    build_removal_list

    step "Pacotes a remover:"
    for pkg in "${REMOVAL_LIST[@]}"; do
        [ -n "$pkg" ] && echo -e "  ${RED}−${RC} $pkg"
    done
    echo ""

    if [[ ${#IDES_FOUND[@]} -gt 0 ]]; then
        echo -e "  ${GREEN}Preservados (IDEs detectadas):${RC}"
        for ide in "${IDES_FOUND[@]}"; do
            echo -e "  ${GREEN}✓${RC} $ide"
        done
        echo ""
    fi

    echo -ne "${YELLOW}Confirmar remoção? [s/N]:${RC} "
    read -r confirm < /dev/tty
    if [[ ! "$confirm" =~ ^[sS]$ ]]; then
        warn "Desinstalação cancelada."
        return
    fi

    step "Removendo pacotes..."
    local pkgs_to_remove=()
    for pkg in "${REMOVAL_LIST[@]}"; do
        [ -n "$pkg" ] && pkgs_to_remove+=("$pkg")
    done

    if pacman -Q "${pkgs_to_remove[@]}" &>/dev/null 2>&1; then
        pacman -Rns --noconfirm "${pkgs_to_remove[@]}" 2>/dev/null || \
            warn "Alguns pacotes não puderam ser removidos (podem não estar instalados)"
    else
        for pkg in "${pkgs_to_remove[@]}"; do
            if pacman -Q "$pkg" &>/dev/null 2>&1; then
                pacman -Rns --noconfirm "$pkg" 2>/dev/null && success "Removido: $pkg" || warn "Falha ao remover: $pkg"
            fi
        done
    fi
}

run_uninstall() {
    echo ""
    echo -e "${RED}${BOLD}  ╔══════════════════════════════════════╗${RC}"
    echo -e "${RED}${BOLD}  ║        DESINSTALAÇÃO SEGURA          ║${RC}"
    echo -e "${RED}${BOLD}  ╚══════════════════════════════════════╝${RC}"
    echo ""

    detect_ides

    if [[ ${#IDES_FOUND[@]} -gt 0 ]]; then
        info "IDEs detectadas no sistema:"
        for ide in "${IDES_FOUND[@]}"; do
            echo -e "  ${GREEN}✓${RC} $ide — ${CYAN}será preservado${RC}"
        done
        echo ""
    else
        info "Nenhuma IDE protegida detectada."
    fi

    echo -e "${YELLOW}O que deseja fazer?${RC}"
    echo ""
    echo -e "  ${CYAN}1)${RC} Remover apenas os dotfiles (configs do Hyprland/Waybar/Rofi...)"
    echo -e "  ${CYAN}2)${RC} Remover pacotes instalados pelo script"
    echo -e "  ${CYAN}3)${RC} Remover tudo (dotfiles + pacotes)"
    echo -e "  ${CYAN}0)${RC} Voltar"
    echo ""
    echo -ne "${YELLOW}Escolha:${RC} "
    read -r unsub_choice < /dev/tty

    case "$unsub_choice" in
        1) remove_dotfiles ;;
        2) remove_packages ;;
        3)
            remove_dotfiles
            remove_packages
            ;;
        0) return ;;
        *)
            warn "Opção inválida."
            run_uninstall
            ;;
    esac

    echo ""
    success "Desinstalação concluída."
    warn "Recomenda-se reiniciar o sistema."
}

main_menu() {
    banner
    check_root

    echo -e "  ${BOLD}O que você deseja fazer?${RC}"
    echo ""
    echo -e "  ${CYAN}1)${RC} ${GREEN}Instalar${RC}     — Configurar Hyprland e todos os dotfiles"
    echo -e "  ${CYAN}2)${RC} ${RED}Desinstalar${RC}  — Remover pacotes/dotfiles de forma segura"
    echo -e "  ${CYAN}0)${RC} Sair"
    echo ""
    echo -ne "  ${YELLOW}Escolha uma opção [0-2]:${RC} "
    read -r choice < /dev/tty

    echo ""
    case "$choice" in
        1) run_install ;;
        2) run_uninstall ;;
        0)
            info "Saindo."
            exit 0
            ;;
        *)
            warn "Opção inválida. Tente novamente."
            sleep 1
            main_menu
            ;;
    esac
}

main_menu