#!/bin/bash
set -eu

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RC='\033[0m'

INSTALL_USER=${SUDO_USER:-$USER}
USER_HOME=$(eval echo ~"$INSTALL_USER")
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PACMAN_FLAGS="-S --needed --noconfirm --noprogressbar"

root_permission() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Please run as root or with sudo${RC}"
        exit 1
    fi
    echo -e "${GREEN}Running with root privileges${RC}"
}

install_yay() {
    echo -e "${YELLOW}Installing yay...${RC}"
    pacman $PACMAN_FLAGS git base-devel
    cd /tmp
    sudo -u "$INSTALL_USER" git clone https://aur.archlinux.org/yay.git
    cd yay
    sudo -u "$INSTALL_USER" makepkg -si --noconfirm
    cd ..
    rm -rf yay
    echo -e "${GREEN}yay installed successfully${RC}"
}

check_yay() {
    if ! sudo -u "$INSTALL_USER" bash -lc "command -v yay" &>/dev/null; then
        install_yay
    fi
}

enable_multilib() {
    if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
        echo -e "${YELLOW}Enabling multilib repository...${RC}"
        sed -i '/^#\[multilib\]/{s/^#//;n;s/^#//}' /etc/pacman.conf
        pacman -Syu --noconfirm
        echo -e "${GREEN}Multilib enabled${RC}"
    else
        echo -e "${GREEN}Multilib already enabled${RC}"
    fi
}

configure_tlp() {
    echo -e "${YELLOW}Configuring TLP...${RC}"
    pacman $PACMAN_FLAGS tlp tlp-rdw
    systemctl enable --now tlp
    echo -e "${GREEN}TLP configured${RC}"
}

gaming_dependencies() {
    echo -e "${YELLOW}Installing gaming libs...${RC}"
    pacman $PACMAN_FLAGS lib32-gnutls lib32-gtk3 lib32-libpulse lib32-alsa-lib \
        lib32-libpng lib32-libjpeg-turbo lib32-sqlite lib32-libva \
        lib32-vulkan-icd-loader lib32-vulkan-radeon lib32-vulkan-intel \
        vulkan-icd-loader vulkan-radeon vulkan-intel ocl-icd opencl-icd-loader \
        gamemode mangohud gamescope
    echo -e "${GREEN}Gaming libs installed${RC}"
}

configure_terminus_font() {
    pacman $PACMAN_FLAGS terminus-font
    if [ -f /etc/vconsole.conf ]; then
        grep -q "^FONT=ter-v18b" /etc/vconsole.conf \
            || sed -i 's/^FONT=.*/FONT=ter-v18b/' /etc/vconsole.conf
    else
        echo "FONT=ter-v18b" > /etc/vconsole.conf
    fi
    [ -z "${DISPLAY:-}" ] && [ -z "${WAYLAND_DISPLAY:-}" ] && setfont ter-v18b || true
    echo -e "${GREEN}Terminus font configured${RC}"
}

copy_dotfiles() {
    # SCRIPT_DIR é distro/arch/ — os dotfiles já estão aqui
    local DOTFILES_SOURCE="$SCRIPT_DIR"
    local CONFIG_DIR="$USER_HOME/.config"

    runuser -u "$INSTALL_USER" -- mkdir -p "$CONFIG_DIR"

    if command -v rsync &>/dev/null; then
        runuser -u "$INSTALL_USER" -- rsync -a --delete "$DOTFILES_SOURCE/." "$CONFIG_DIR/"
    else
        runuser -u "$INSTALL_USER" -- cp -a "$DOTFILES_SOURCE/." "$CONFIG_DIR/"
    fi
    echo -e "${GREEN}Dotfiles copied from $DOTFILES_SOURCE${RC}"
}

setup_wallpapers() {
    local PICTURES_DIR
    PICTURES_DIR=$(sudo -u "$INSTALL_USER" bash -lc 'echo "${XDG_PICTURES_DIR:-$HOME/Pictures}"')
    local WALL_DIR="$PICTURES_DIR/wallpapers"

    runuser -u "$INSTALL_USER" -- mkdir -p "$WALL_DIR"
    if [ -d "$WALL_DIR/.git" ]; then
        runuser -u "$INSTALL_USER" -- git -C "$WALL_DIR" pull --ff-only
    else
        runuser -u "$INSTALL_USER" -- git clone --depth=1 \
            https://github.com/csouzape/wallpapers "$WALL_DIR"
    fi
    echo -e "${GREEN}Wallpapers ready at: $WALL_DIR${RC}"
}

detect_de() {
    local DE=""
    DE=$(sudo -u "$INSTALL_USER" bash -lc \
        'echo "${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION:-}}"' 2>/dev/null || true)
    echo "${DE:-UNKNOWN}"
}

remove_old_de() {
    local DE
    DE=$(detect_de | tr '[:lower:]' '[:upper:]')
    case "$DE" in
        *KDE*|*PLASMA*)
            pacman -Rns --noconfirm plasma-desktop plasma-workspace \
                kde-applications kwalletmanager || true
            ;;
        *GNOME*)
            pacman -Rns --noconfirm gnome-shell gnome-control-center \
                gnome-terminal nautilus || true
            ;;
        *XFCE*)
            pacman -Rns --noconfirm xfce4-session xfce4-panel \
                xfdesktop xfwm4 || true
            ;;
        *MATE*)
            pacman -Rns --noconfirm mate-session-manager \
                mate-panel mate-desktop || true
            ;;
        *CINNAMON*)
            pacman -Rns --noconfirm cinnamon || true
            ;;
        *)
            echo -e "${YELLOW}No DE detected or unsupported DE: ${DE}${RC}"
            ;;
    esac
}

install_flatpak() {
    if ! command -v flatpak &>/dev/null; then
        echo -e "${YELLOW}Installing Flatpak...${RC}"
        pacman $PACMAN_FLAGS flatpak
        flatpak remote-add --if-not-exists flathub \
            https://dl.flathub.org/repo/flathub.flatpakrepo
        echo -e "${GREEN}Flatpak installed${RC}"
    fi
}

install_dependencies_flatpak() {
    local flatpak_packages=(
        flathub com.github.zocker_160.SyncThingy
    )

    install_flatpak

    for pkg in "${flatpak_packages[@]}"; do
        if flatpak info "$pkg" &>/dev/null; then
            echo -e "${GREEN}$pkg already installed${RC}"
        else
            echo -e "${YELLOW}Installing $pkg...${RC}"
            flatpak install -y flathub "$pkg"
        fi
    done
}

install_dependencies_pacman() {
    pacman $PACMAN_FLAGS hyprland sddm alacritty thunar pavucontrol waybar \
        xdg-desktop-portal-hyprland hyprshot swaync rofi swww \
        playerctl materia-gtk-theme nwg-look ttf-jetbrains-mono \
        papirus-icon-theme discord noto-fonts noto-fonts-emoji \
        ttf-liberation ttf-dejavu
    echo -e "${GREEN}Main packages installed${RC}"
}

install_dependencies_aur() {
    local aur_packages=(google-chrome waypaper spotify visual-studio-code-bin)
    for pkg in "${aur_packages[@]}"; do
        if ! pacman -Qi "$pkg" &>/dev/null; then
            sudo -u "$INSTALL_USER" bash -lc "yay -S --noconfirm $pkg"
        fi
    done
    echo -e "${GREEN}AUR packages installed${RC}"
}

sddm_config() {
    echo -e "${YELLOW}Enabling SDDM display manager...${RC}"
    systemctl enable --now sddm.service
    echo -e "${GREEN}SDDM enabled and started${RC}"
}

installfastfetch() {
    if ! command -v fastfetch &>/dev/null; then
        echo -e "${YELLOW}Installing fastfetch...${RC}"
        pacman $PACMAN_FLAGS fastfetch
        echo -e "${GREEN}fastfetch installed${RC}"
    else
        echo -e "${GREEN}fastfetch already installed${RC}"
    fi
}

configfastfetch() {
    if ! command -v curl &>/dev/null; then
        echo -e "${YELLOW}Installing curl...${RC}"
        pacman $PACMAN_FLAGS curl
    fi

    local CONFIG_DIR="$USER_HOME/.config/fastfetch"
    runuser -u "$INSTALL_USER" -- mkdir -p "$CONFIG_DIR"
    curl -sSLo "$CONFIG_DIR/config.jsonc" \
        https://raw.githubusercontent.com/ChrisTitusTech/mybash/main/config.jsonc
    echo -e "${GREEN}fastfetch configured${RC}"
}

setup_fastfetch_shell_arch() {
    echo -e "${YELLOW}Configuring fastfetch shell integration...${RC}"

    local current_shell
    current_shell=$(basename "$(getent passwd "$INSTALL_USER" | cut -d: -f7)")

    local rc_file=""
    case "$current_shell" in
        bash) rc_file="$USER_HOME/.bashrc" ;;
        zsh)  rc_file="$USER_HOME/.zshrc" ;;
        fish) rc_file="$USER_HOME/.config/fish/config.fish" ;;
        *)
            echo -e "${YELLOW}Shell '$current_shell' not supported for auto-config.${RC}"
            return 0
            ;;
    esac

    [ -f "$rc_file" ] || return 0

    if grep -q "^fastfetch" "$rc_file"; then
        echo -e "${GREEN}fastfetch already configured in $rc_file${RC}"
        return 0
    fi

    printf "\n# Run fastfetch on shell initialization\nfastfetch\n" >> "$rc_file"
    echo -e "${GREEN}fastfetch added to $rc_file${RC}"
}

main() {
    echo -e "${BLUE}========================================${RC}"
    echo -e "${BLUE}      Hyprland Setup Script (Arch)      ${RC}"
    echo -e "${BLUE}========================================${RC}"
    root_permission

    echo "1) Install Hyprland"
    echo "2) Remove KDE Plasma only"
    echo "3) Cancel"
    read -rp "Select an option [1-3]: " MENU < /dev/tty

    case "$MENU" in
        1)
            remove_old_de
            check_yay
            enable_multilib
            configure_tlp
            install_dependencies_pacman
            install_dependencies_aur
            install_dependencies_flatpak
            gaming_dependencies
            configure_terminus_font
            copy_dotfiles
            setup_wallpapers
            installfastfetch
            configfastfetch
            setup_fastfetch_shell_arch
            sddm_config
            echo -e "${GREEN}Hyprland installation complete!${RC}"
            ;;
        2)
            pacman -Rns --noconfirm plasma-desktop plasma-workspace \
                kde-applications kwalletmanager || true
            echo -e "${GREEN}KDE removed${RC}"
            ;;
        3)
            echo -e "${YELLOW}Cancelled${RC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option${RC}"
            exit 0
            ;;
    esac
}

main "$@"