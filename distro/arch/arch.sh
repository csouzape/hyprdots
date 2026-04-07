#!/usr/bin/env bash
set -euo pipefail

USER_NAME="${SUDO_USER:-$USER}"

PACMAN_PACKAGES=(
    hyprland
    swaync
    waybar
    rofi
    materia-gtk-theme
    papirus-icon-theme
    alacritty
    thunar
)

AUR_PACKAGES=(
    brave
)

FLATPAK_PACKAGES=(
    org.vinegarhq.Sober
    com.discordapp.Discord
)

log() {
    printf "[INFO] %s\n" "$1"
}

error() {
    printf "[ERROR] %s\n" "$1" >&2
    exit 1
}

run_as_user() {
    sudo -u "$USER_NAME" bash -c "$1"
}

verify_root() {
    [[ "$EUID" -eq 0 ]] || error "Run as root"
}

verify_dependencies() {
    log "Checking base dependencies"
    pacman -S --noconfirm --needed git base-devel
}


install_yay() {
    if command -v yay &>/dev/null; then
        log "yay already installed"
        return
    fi

    log "Installing yay (AUR)"
    run_as_user "
        set -e
        cd /tmp
        rm -rf yay
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si --noconfirm
        cd ..
        rm -rf yay
    "
}


install_pacman() {
    log "Installing pacman packages"
    pacman -S --noconfirm --needed "${PACMAN_PACKAGES[@]}"
}

install_aur() {
    log "Installing AUR packages"
    run_as_user "yay -S --noconfirm --needed ${AUR_PACKAGES[*]}"
}

install_flatpak() {
    if ! command -v flatpak &>/dev/null; then
        log "Installing flatpak"
        pacman -S --noconfirm --needed flatpak
    fi

    run_as_user "
        flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
        flatpak install -y ${FLATPAK_PACKAGES[*]}
    "
}

copy_configs() {
    log "Copying configs to ~/.config"

    run_as_user "
        set -e

        SRC_DIR=\"$(pwd)/hyprdots/distro/arch\"
        DEST_DIR=\"\$HOME/.config\"

        mkdir -p \"\$DEST_DIR\"

        cp -r \"\$SRC_DIR\"/* \"\$DEST_DIR\"/
    "
}

main() {
    verify_root
    verify_dependencies
    install_yay
    install_pacman
    install_aur
    install_flatpak
    copy_configs
    log "Done"
}

main "$@"