#!/bin/bash
# distro/fedora/fedora.sh — Instalação para Fedora KDE → Hyprland
set -e


RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RC='\033[0m'

INSTALL_USER="${SUDO_USER:-$USER}"
USER_HOME=$(eval echo ~"$INSTALL_USER")
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DNF_FLAGS="-y"
HYPR_COPR="${HYPR_COPR:-solopasha/hyprland}"

info()    { echo -e "${BLUE}[INFO]${RC}  $1"; }
success() { echo -e "${GREEN}[OK]${RC}    $1"; }
warn()    { echo -e "${YELLOW}[WARN]${RC}  $1"; }
error()   { echo -e "${RED}[ERRO]${RC}  $1"; }
step()    { echo -e "\n${CYAN}${BOLD}==> $1${RC}"; }

root_permission() {
    if [ "$EUID" -ne 0 ]; then
        error "Execute com sudo: ${BOLD}sudo ./hyprdots.sh${RC}"
        exit 1
    fi
    success "Rodando com privilégios root (usuário real: $INSTALL_USER)"
}

detect_ides() {
    IDES_FOUND=()


    if command -v code &>/dev/null || command -v codium &>/dev/null || \
       flatpak list 2>/dev/null | grep -qi "visualstudio.code\|vscodium"; then
        IDES_FOUND+=("vscode")
    fi

 
    if command -v nvim &>/dev/null; then
        IDES_FOUND+=("neovim")
    fi
}

enable_hypr_repo() {
    step "Habilitando repositório COPR: $HYPR_COPR"

    dnf install ${DNF_FLAGS} dnf-plugins-core

    if dnf copr list 2>/dev/null | grep -q "$HYPR_COPR"; then
        success "Repositório já habilitado"
    else
        dnf copr enable -y "$HYPR_COPR"
        success "Repositório habilitado"
    fi
}

install_packages() {
    step "Instalando pacotes via dnf"

    local PACKAGES=(
        hyprland
        xdg-desktop-portal-hyprland
        xdg-desktop-portal-gtk
        wayland
        waybar
        rofi
        alacritty
        sddm
        swaync
        swww
        waypaper
        hyprshot
        playerctl
        pavucontrol
        thunar
        nwg-look
        sassc
        jetbrains-mono-fonts
        zathura
        zathura-pdf-poppler
        swayimg
        meson
        ninja-build
        npm
        git
        wget
        rsync
    )

    dnf install ${DNF_FLAGS} "${PACKAGES[@]}"

    if ! command -v Hyprland &>/dev/null; then
        error "Hyprland não foi instalado corretamente"
        exit 1
    fi

    success "Todos os pacotes instalados"
}

flatpak_install() {
    step "Instalando aplicações Flatpak"

    if ! command -v flatpak &>/dev/null; then
        warn "Flatpak não encontrado. Instalando..."
        dnf install -y flatpak || { error "Falha ao instalar Flatpak"; return 1; }
    fi

    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

    local FLATPAKS=(
        com.spotify.Client
        com.visualstudio.code
        com.github.tchx84.Flatseal
        com.discordapp.Discord
        io.github.martchus.syncthingtray
        md.obsidian.Obsidian
    )

    for app in "${FLATPAKS[@]}"; do
        flatpak install -y flathub "$app" || warn "Falha ao instalar Flatpak: $app"
    done

    success "Aplicações Flatpak instaladas"
}

google_chrome_install() {
    step "Instalando Google Chrome"

    if command -v google-chrome-stable &>/dev/null; then
        success "Google Chrome já instalado"
        return
    fi

    command -v wget &>/dev/null || dnf install -y wget

    local DOWNLOAD_PATH="/tmp/google-chrome.rpm"

    wget -O "$DOWNLOAD_PATH" \
        https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm \
        || { error "Falha ao baixar Google Chrome"; return 1; }

    dnf install -y "$DOWNLOAD_PATH" || { error "Falha ao instalar Google Chrome"; return 1; }

    rm -f "$DOWNLOAD_PATH"
    success "Google Chrome instalado"
}

configure_tlp() {
    step "Configurando TLP"
    if systemctl is-enabled tuned &>/dev/null; then
        warn "Desabilitando tuned (conflito com TLP)..."
        systemctl disable --now tuned.service || true
        dnf remove ${DNF_FLAGS} tuned || true
    fi

    dnf install ${DNF_FLAGS} tlp tlp-rdw
    systemctl enable --now tlp
    success "TLP configurado"
}

install_materia_theme() {
    step "Instalando Materia Theme"

    for dep in git meson ninja sassc; do
        command -v "$dep" &>/dev/null || { error "Dependência ausente: $dep"; return 1; }
    done

    local TMP_DIR
    TMP_DIR="$(mktemp -d /tmp/materia-theme.XXXXXX)"
    trap "rm -rf $TMP_DIR" RETURN

    git clone --depth=1 https://github.com/nana-4/materia-theme.git "$TMP_DIR" || return 1
    meson setup --prefix=/usr "$TMP_DIR/build" "$TMP_DIR" || return 1
    ninja -C "$TMP_DIR/build" || return 1
    ninja -C "$TMP_DIR/build" install || return 1

    success "Materia Theme instalado"
}

wallpapers_config() {
    step "Configurando wallpapers"

    local TARGET_DIR="$USER_HOME/Pictures/wallpapers"
    runuser -u "$INSTALL_USER" -- mkdir -p "$TARGET_DIR" || return 1

    if [ -d "$TARGET_DIR/.git" ]; then
        warn "Atualizando wallpapers existentes..."
        runuser -u "$INSTALL_USER" -- git -C "$TARGET_DIR" pull --ff-only \
            || { error "Falha ao atualizar wallpapers"; return 1; }
    else
        runuser -u "$INSTALL_USER" -- git clone --depth=1 \
            https://github.com/csouzape/wallpapers "$TARGET_DIR" \
            || { error "Falha ao clonar wallpapers"; return 1; }
    fi

    success "Wallpapers prontos em ~/Pictures/wallpapers"
}

configure_sddm() {
    step "Configurando SDDM"

    if ! rpm -q sddm &>/dev/null; then
        warn "SDDM não encontrado. Instalando..."
        dnf install -y sddm || { error "Falha ao instalar SDDM"; return 1; }
    fi

    systemctl enable sddm.service --force
    systemctl set-default graphical.target
    success "SDDM configurado como display manager padrão"
}

configure_auto_login() {
    step "Configurando auto-login para $INSTALL_USER"

    local SDDM_CONF="/etc/sddm.conf"

    if grep -q "AutoLoginUser=$INSTALL_USER" "$SDDM_CONF" 2>/dev/null; then
        success "Auto-login já configurado para $INSTALL_USER"
        return 0
    fi

    cat > "$SDDM_CONF" << SDDM
[Autologin]
User=$INSTALL_USER
Session=hyprland
SDDM

    success "Auto-login configurado para $INSTALL_USER"
}

remove_kde() {
    step "Removendo KDE Plasma"

    warn "Isso removerá o KDE Plasma e componentes relacionados."
    echo -ne "${YELLOW}Confirmar remoção do KDE? [s/N]:${RC} "
    read -r confirm < /dev/tty
    [[ ! "$confirm" =~ ^[sS]$ ]] && { warn "Cancelado."; return; }

    dnf group remove -y "KDE Plasma Workspaces" || true
    dnf remove -y --setopt=protected_packages= \
        plasma-desktop plasma-workspace* plasma-* \
        kde-* kf5-* kf6-* \
        konsole dolphin ark gwenview || true

    success "KDE Plasma removido"
}

copy_dotfiles() {
    step "Copiando dotfiles"

    [ -z "${INSTALL_USER:-}" ] && { error "INSTALL_USER não definido"; return 1; }

    local CONFIG_DIR="$USER_HOME/.config"
    local DOTFILES_SOURCE="$SCRIPT_DIR"

    info "Fonte dos dotfiles: $DOTFILES_SOURCE"
    runuser -u "$INSTALL_USER" -- mkdir -p "$CONFIG_DIR" || return 1

    if command -v rsync &>/dev/null; then
        runuser -u "$INSTALL_USER" -- rsync -a --delete "$DOTFILES_SOURCE/." "$CONFIG_DIR/" || return 1
    else
        runuser -u "$INSTALL_USER" -- cp -a "$DOTFILES_SOURCE/." "$CONFIG_DIR/" || return 1
    fi

    # Valida arquivos essenciais
    for file in "hypr/hyprland.conf" "waybar/config"; do
        if [ ! -f "$CONFIG_DIR/$file" ]; then
            warn "Arquivo essencial ausente: $file — verifique manualmente"
        fi
    done

    success "Dotfiles copiados"
}

monitor_hint() {
    step "Verificando monitor"
    warn "As configs do waybar usam nomes de monitor fixos do autor."
    warn "Após o reboot, rode: ${CYAN}hyprctl monitors${RC}"
    warn "E ajuste o campo ${CYAN}\"output\"${RC} em ~/.config/waybar/config"
}

FEDORA_PACKAGES=(
    hyprland xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
    waybar rofi alacritty swaync swww waypaper hyprshot
    playerctl pavucontrol thunar nwg-look
    zathura zathura-pdf-poppler swayimg
    jetbrains-mono-fonts
)

VSCODE_PROTECTED_FLATPAKS=("com.visualstudio.code" "com.vscodium.codium")
NEOVIM_PROTECTED_PKGS=("neovim")

run_uninstall() {
    step "Desinstalação Segura — Fedora"

    detect_ides

    if [[ ${#IDES_FOUND[@]} -gt 0 ]]; then
        info "IDEs detectadas (serão preservadas):"
        for ide in "${IDES_FOUND[@]}"; do
            echo -e "  ${GREEN}✓${RC} $ide"
        done
        echo ""
    else
        info "Nenhuma IDE protegida detectada."
    fi

    echo -e "${YELLOW}O que deseja remover?${RC}"
    echo ""
    echo -e "  ${CYAN}1)${RC} Remover apenas os dotfiles (configs do Hyprland/Waybar/Rofi...)"
    echo -e "  ${CYAN}2)${RC} Remover pacotes DNF instalados pelo script"
    echo -e "  ${CYAN}3)${RC} Remover Flatpaks instalados pelo script"
    echo -e "  ${CYAN}4)${RC} Remover tudo (dotfiles + pacotes + flatpaks)"
    echo -e "  ${CYAN}0)${RC} Voltar"
    echo ""
    echo -ne "${YELLOW}Escolha:${RC} "
    read -r unsub_choice < /dev/tty

    case "$unsub_choice" in
        1) _remove_dotfiles_fedora ;;
        2) _remove_dnf_packages ;;
        3) _remove_flatpaks ;;
        4)
            _remove_dotfiles_fedora
            _remove_dnf_packages
            _remove_flatpaks
            ;;
        0) return ;;
        *)
            warn "Opção inválida."
            run_uninstall
            ;;
    esac

    success "Desinstalação concluída."
    warn "Recomenda-se reiniciar o sistema."
}

_remove_dotfiles_fedora() {
    step "Removendo dotfiles"

    local configs=(
        "$USER_HOME/.config/hypr"
        "$USER_HOME/.config/waybar"
        "$USER_HOME/.config/rofi"
        "$USER_HOME/.config/alacritty"
        "$USER_HOME/.config/swaync"
        "$USER_HOME/.config/swww"
    )

    for cfg in "${configs[@]}"; do
        if [ -d "$cfg" ] || [ -L "$cfg" ]; then
            rm -rf "$cfg"
            success "Removido: $cfg"
        fi
    done
}

_remove_dnf_packages() {
    step "Removendo pacotes DNF"

    local removal_list=("${FEDORA_PACKAGES[@]}")

    if [[ " ${IDES_FOUND[*]} " =~ "neovim" ]]; then
        warn "Neovim detectado → pacote preservado"
        for pkg in "${NEOVIM_PROTECTED_PKGS[@]}"; do
            removal_list=("${removal_list[@]/$pkg}")
        done
    fi

    echo -e "${YELLOW}Pacotes a remover:${RC}"
    for pkg in "${removal_list[@]}"; do
        [ -n "$pkg" ] && echo -e "  ${RED}−${RC} $pkg"
    done
    echo ""

    echo -ne "${YELLOW}Confirmar? [s/N]:${RC} "
    read -r confirm < /dev/tty
    [[ ! "$confirm" =~ ^[sS]$ ]] && { warn "Cancelado."; return; }

    for pkg in "${removal_list[@]}"; do
        if [ -n "$pkg" ] && rpm -q "$pkg" &>/dev/null; then
            dnf remove -y "$pkg" && success "Removido: $pkg" || warn "Falha ao remover: $pkg"
        fi
    done
}

_remove_flatpaks() {
    step "Removendo Flatpaks"

    detect_ides

    local flatpaks_to_remove=(
        com.spotify.Client
        com.visualstudio.code
        com.github.tchx84.Flatseal
        com.discordapp.Discord
        io.github.martchus.syncthingtray
        md.obsidian.Obsidian
    )

    # Protege VS Code Flatpak se detectado
    if [[ " ${IDES_FOUND[*]} " =~ "vscode" ]]; then
        warn "VS Code detectado → Flatpak do VS Code preservado"
        flatpaks_to_remove=("${flatpaks_to_remove[@]/com.visualstudio.code}")
    fi

    echo -e "${YELLOW}Flatpaks a remover:${RC}"
    for app in "${flatpaks_to_remove[@]}"; do
        [ -n "$app" ] && echo -e "  ${RED}−${RC} $app"
    done
    echo ""

    echo -ne "${YELLOW}Confirmar? [s/N]:${RC} "
    read -r confirm < /dev/tty
    [[ ! "$confirm" =~ ^[sS]$ ]] && { warn "Cancelado."; return; }

    for app in "${flatpaks_to_remove[@]}"; do
        if [ -n "$app" ] && flatpak list 2>/dev/null | grep -q "$app"; then
            flatpak uninstall -y "$app" && success "Removido: $app" || warn "Falha ao remover: $app"
        fi
    done
}

main() {
    echo -e "${BLUE}${BOLD}"
    echo "  ╔══════════════════════════════════════════════════╗"
    echo "  ║   Hyprland Setup — Fedora KDE                    ║"
    echo "  ║   Usuário: $INSTALL_USER"
    echo "  ║   Home:    $USER_HOME"
    echo "  ╚══════════════════════════════════════════════════╝"
    echo -e "${RC}"

    root_permission

    echo -e "  ${BOLD}O que você deseja fazer?${RC}"
    echo ""
    echo -e "  ${CYAN}1)${RC} ${GREEN}Instalar Hyprland${RC}          — Instala tudo e migra do KDE"
    echo -e "  ${CYAN}2)${RC} ${YELLOW}Remover KDE Plasma${RC}         — Remove o KDE e configura SDDM"
    echo -e "  ${CYAN}3)${RC} ${RED}Desinstalar (seguro)${RC}       — Remove pacotes/dotfiles preservando IDEs"
    echo -e "  ${CYAN}0)${RC} Cancelar"
    echo ""
    echo -ne "  ${YELLOW}Escolha [0-3]:${RC} "
    read -r MENU_OPTION < /dev/tty

    echo ""
    case "$MENU_OPTION" in
        1)
            step "Iniciando instalação completa do Hyprland..."
            enable_hypr_repo
            install_packages
            configure_tlp
            install_materia_theme
            wallpapers_config
            flatpak_install
            google_chrome_install
            copy_dotfiles || warn "Alguns configs podem estar ausentes — verifique manualmente"
            configure_sddm
            configure_auto_login
            monitor_hint
            echo ""
            echo -e "${GREEN}${BOLD}"
            echo "  ╔══════════════════════════════════════════════════╗"
            echo "  ║  Instalação concluída!                           ║"
            echo "  ║  → Reinicie e o Hyprland iniciará automaticamente║"
            echo "  ╚══════════════════════════════════════════════════╝"
            echo -e "${RC}"
            ;;
        2)
            remove_kde
            configure_sddm
            configure_auto_login
            success "KDE removido e SDDM configurado."
            ;;
        3)
            run_uninstall
            ;;
        0)
            warn "Cancelado."
            exit 0
            ;;
        *)
            error "Opção inválida."
            exit 1
            ;;
    esac
}

main "$@"