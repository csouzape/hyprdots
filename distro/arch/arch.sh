#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

install_hyprland() {

    local PACMAN=(
        hyprland
        waybar
        swaync
        grim
        slurp
        rofi
        alacritty
        wl-clipboard
        nwg-look
        materia-gtk-theme
        papirus-icon-theme
        xdg-desktop-portal
        xdg-desktop-portal-gtk
        xdg-desktop-portal-hyprland
        discord
        obs-studio
        waypaper
    )

    local AUR=(
        hyprpaper
        visual-studio-code-bin
        brave-bin
    )

    local FLATPAK=(
        com.github.zocker_160.Syncthingy
        org.localsend.localsend_app
    )

    echo "==> Installing pacman packages..."
    sudo pacman -S --needed "${PACMAN[@]}" || return 1

    echo "==> Installing AUR packages..."
    yay -S --needed "${AUR[@]}" || return 1

    if ! command -v flatpak &>/dev/null; then
        echo "Flatpak not found."

        read -rp "Do you want to install Flatpak? (y/n): " answer

        if [[ "$answer" == "y" ]]; then
            sudo pacman -S --needed flatpak

            flatpak remote-add --if-not-exists flathub \
            https://dl.flathub.org/repo/flathub.flatpakrepo
        else
            return 1
        fi
    fi

    echo "==> Installing Flatpak packages..."

    for pkg in "${FLATPAK[@]}"; do
        if ! flatpak list --app | grep -q "$pkg"; then
            flatpak install flathub "$pkg" -y
        else
            echo "$pkg is already installed."
        fi
    done
}

copy_dotfiles() {

    if [[ -d "$HOME/.config/hypr" ]]; then
        echo "Hyprland configuration already exists. Skipping."
    else
        echo "Copying dotfiles..."

        mkdir -p "$HOME/.config/hypr"

        cp -r "$SCRIPT_DIR/distro/arch/hypr/." \
        "$HOME/.config/hypr/"
    fi
}

install_hyprland
copy_dotfiles