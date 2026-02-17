#!/bin/bash
set -e

# ── Color codes ──────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RC='\033[0m'

INSTALL_USER=${SUDO_USER:-$USER}
USER_HOME=$(eval echo ~$INSTALL_USER)

DNF_FLAGS="-y"

# ── Root check ──────────────────────────────
root_permission() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Please run as root or with sudo${RC}"
        exit 1
    fi
    echo -e "${GREEN}Running with root privileges${RC}"
}

# ── DE detection & removal ─────────────────
detect_de() {
    local DE=""
    [ -n "$XDG_CURRENT_DESKTOP" ] && DE="$XDG_CURRENT_DESKTOP"
    [ -z "$DE" ] && [ -n "$DESKTOP_SESSION" ] && DE="$DESKTOP_SESSION"
    [ -z "$DE" ] && DE="UNKNOWN"
    echo "$DE"
}

remove_de() {
    local DE=$(detect_de | tr '[:lower:]' '[:upper:]')
    case "$DE" in
        *KDE*|*PLASMA*)
            echo -e "${YELLOW}Removing KDE Plasma...${RC}"
            dnf group remove -y "KDE Plasma Workspaces"
            dnf remove -y plasma-* kde-* kf5-* kf6-* konsole dolphin ark gwenview || true
            ;;
        *GNOME*)
            echo -e "${YELLOW}Removing GNOME...${RC}"
            dnf group remove -y "GNOME Desktop Environment"
            dnf remove -y gnome-shell gnome-terminal nautilus gnome-control-center || true
            ;;
        *XFCE*)
            echo -e "${YELLOW}Removing XFCE...${RC}"
            dnf group remove -y "Xfce Desktop"
            dnf remove -y xfce4* || true
            ;;
        *)
            echo -e "${YELLOW}No recognized DE found or already removed${RC}"
            ;;
    esac
    echo -e "${GREEN}DE removal completed${RC}"
}

# ── Display manager ────────────────────────
configure_sddm() {
    if ! rpm -q sddm &>/dev/null; then
        echo -e "${YELLOW}Installing SDDM...${RC}"
        dnf install -y sddm
    fi
    systemctl enable sddm.service --force
    systemctl set-default graphical.target
    echo -e "${GREEN}SDDM configured${RC}"
}

# ── Hyprland repo ──────────────────────────
enable_hypr_repo() {
    dnf install -y dnf-plugins-core
    local HYPR_COPR=${HYPR_COPR:-solopasha/hyprland}
    if ! dnf copr list 2>/dev/null | grep -q "$HYPR_COPR"; then
        dnf copr enable -y "$HYPR_COPR"
        echo -e "${GREEN}Hyprland COPR enabled${RC}"
    else
        echo -e "${GREEN}Hyprland COPR already enabled${RC}"
    fi
}

# ── Package installation ───────────────────
install_packages() {
    local PACKAGES=(
        hyprland sddm alacritty thunar pavucontrol jetbrains-mono-fonts
        waybar xdg-desktop-portal-gtk hyprshot swaync rofi waypaper swww playerctl
        breeze-gtk nwg-look
    )
    echo -e "${YELLOW}Installing Fedora packages...${RC}"
    dnf install ${DNF_FLAGS} "${PACKAGES[@]}"
    echo -e "${GREEN}Package installation completed${RC}"
}

flatpak_install() {
    local FLATPAK_PACKAGES=(com.spotify.Client com.visualstudio.code com.github.tchx84.Flatseal)
    for pkg in "${FLATPAK_PACKAGES[@]}"; do
        flatpak list --app | grep -q "$pkg" || flatpak install -y flathub "$pkg"
    done
    echo -e "${GREEN}Flatpak installation completed${RC}"
}

# ── TLP setup ─────────────────────────────
configure_tlp() {
    dnf remove -y tuned || true
    dnf install -y tlp tlp-rdw
    systemctl enable --now tlp
    echo -e "${GREEN}TLP configured${RC}"
}

# ── Dotfiles copy ──────────────────────────
copy_dotfiles() {
    local DOTFILES_SOURCE="$USER_HOME/hyprdots/distro/fedora"
    [ ! -d "$DOTFILES_SOURCE" ] && DOTFILES_SOURCE="$USER_HOME/hyprdots/fedora"
    [ ! -d "$DOTFILES_SOURCE" ] && DOTFILES_SOURCE="$USER_HOME/hyprdots/distros/fedora"

    if [ ! -d "$DOTFILES_SOURCE" ]; then
        echo -e "${RED}No dotfiles directory found, skipping${RC}"
        return 1
    fi

    local CONFIG_DIR="$USER_HOME/.config"
    runuser -u "$INSTALL_USER" -- mkdir -p "$CONFIG_DIR"

    if command -v rsync &>/dev/null; then
        runuser -u "$INSTALL_USER" -- rsync -a --delete "$DOTFILES_SOURCE/." "$CONFIG_DIR/"
    else
        runuser -u "$INSTALL_USER" -- cp -a "$DOTFILES_SOURCE/." "$CONFIG_DIR/"
    fi
    echo -e "${GREEN}Dotfiles copied successfully${RC}"
}

# ── Wallpapers ────────────────────────────
setup_wallpapers() {
    local WALL_DIR="$USER_HOME/Imagens/wallpapers"
    runuser -u "$INSTALL_USER" -- mkdir -p "$WALL_DIR"
    if [ -d "$WALL_DIR/.git" ]; then
        runuser -u "$INSTALL_USER" -- git -C "$WALL_DIR" pull --ff-only
    else
        runuser -u "$INSTALL_USER" -- git clone --depth=1 https://github.com/csouzape/wallpapers "$WALL_DIR"
    fi
    echo -e "${GREEN}Wallpapers setup completed${RC}"
}

# ── Main ──────────────────────────────────
main() {
    echo -e "${BLUE}========================================${RC}"
    echo -e "${BLUE}  Hyprland Setup Script for Fedora${RC}"
    echo -e "${BLUE}========================================${RC}"

    root_permission
    remove_de
    configure_sddm
    enable_hypr_repo
    install_packages
    copy_dotfiles
    configure_tlp
    setup_wallpapers
    flatpak_install

    echo -e "${GREEN}Hyprland setup completed. Reboot to apply changes.${RC}"
}

main "$@"
