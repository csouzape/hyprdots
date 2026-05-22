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
    )

    local AUR=(
        hyprpaper
        visual-studio-code-bin
        brave-bin
        waypaper
    )

    local FLATPAK=(
        com.github.zocker_160.Syncthingy
        org.localsend.localsend_app
    )

    echo "==> Installing pacman packages..."
    sudo pacman -S --needed "${PACMAN[@]}" || return 1

    echo "==> Installing AUR packages..."
    if command -v yay &>/dev/null; then
        echo "yay found."
    else
        read -rp "yay not found. Install yay? (y/n): " answer
        if [[ "$answer" == "y" ]]; then
            git clone https://aur.archlinux.org/yay.git /tmp/yay
            (cd /tmp/yay && makepkg -si --noconfirm) || return 1
            rm -rf /tmp/yay
        else
            return 1
        fi
    fi
    yay -S --needed "${AUR[@]}" || return 1

    echo "==> Installing Flatpak packages..."
    if ! command -v flatpak &>/dev/null; then
        read -rp "Flatpak not found. Install it? (y/n): " answer
        if [[ "$answer" == "y" ]]; then
            sudo pacman -S --needed flatpak || return 1
            flatpak remote-add --if-not-exists flathub \
                https://dl.flathub.org/repo/flathub.flatpakrepo
            echo "Flatpak installed. You may need to restart your session before Flatpak apps work correctly."
        else
            return 1
        fi
    fi

    for pkg in "${FLATPAK[@]}"; do
        if flatpak list --app | grep -qF "$pkg"; then
            echo "$pkg is already installed."
        else
            flatpak install flathub "$pkg" -y || echo "Warning: failed to install $pkg"
        fi
    done
}

copy_dotfiles() {
    if [[ -d "$HOME/.config/hypr" ]]; then
        echo "Hyprland config already exists at ~/.config/hypr. Skipping."
    else
        echo "Copying dotfiles..."
        mkdir -p "$HOME/.config/hypr"
        cp -r "$SCRIPT_DIR/hypr/." "$HOME/.config/hypr/" || return 1
        echo "Dotfiles copied."
    fi
}

# Only run directly, not when sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_hyprland
    copy_dotfiles
fi