#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
install_pacman_dependences() {
  local PACMAN=(
    hyprland
    waybar
    swaync
    swaybg
    alacritty
    rofi
    thunar
    gvfs
    thunar-volman
    tumbler
    ffmpegthumbnailer
    imv
    grim
    slurp
    wl-clipboard
    xdg-desktop-portal
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
    pavucontrol
    hyprpolkitagent
    qt5-base
    qt5-wayland
    qt6-base
    qt6-wayland
    qt6ct
  )
  echo "==> Installing pacman packages..."
  sudo pacman -S --needed "${PACMAN[@]}" || return 1
}
copy_dotfiles() {
  local SRC="$SCRIPT_DIR"
  local DEST="$HOME/.config"
  echo -e "${BLUE}==> Copying configs to $DEST${RESET}"
  mkdir -p "$DEST"
  local errors=0
  local count=0
  for dir in "$SRC"/*/; do
    [[ -d "$dir" ]] || continue
    local name
    name="$(basename "$dir")"
    if [[ -e "$DEST/$name" ]]; then
      echo -e "${YELLOW}  [update] ~/.config/$name${RESET}"
    else
      echo -e "${CYAN}  [new]    ~/.config/$name${RESET}"
    fi
    if cp -r "$dir" "$DEST/"; then
      echo -e "${GREEN}  [ok]     ~/.config/$name${RESET}"
      ((count++))
    else
      echo -e "${RED}  [fail]   ~/.config/$name${RESET}"
      ((errors++))
    fi
  done
  if [[ $errors -eq 0 ]]; then
    echo -e "${GREEN}==> Done. $count config(s) copied.${RESET}"
  else
    echo -e "${RED}==> Finished with $errors error(s).${RESET}"
    return 1
  fi
}
remove_dependencies() {
  local PACMAN=(
    hyprland
    swaync
    swaybg
    grim
    slurp
    alacritty
    rofi
    thunar
    gvfs
    thunar-volman
    tumbler
    ffmpegthumbnailer
    waybar
    wl-clipboard
    xdg-desktop-portal-hyprland
    pavucontrol
    hyprpolkitagent
    qt5-wayland
    qt6-wayland
    imv
  )
  echo "==> Removing pacman packages..."
  sudo pacman -Rns "${PACMAN[@]}" || return 1
}
remove_files() {
  local SRC="$SCRIPT_DIR"
  local DEST="$HOME/.config"
  echo -e "${BLUE}==> Removing configs from $DEST${RESET}"
  local errors=0
  local count=0
  for dir in "$SRC"/*/; do
    [[ -d "$dir" ]] || continue
    local name
    name="$(basename "$dir")"
    local target="$DEST/$name"
    if [[ ! -e "$target" ]]; then
      echo -e "${YELLOW}  [skip]   ~/.config/$name (dont exist)${RESET}"
      continue
    fi
    if rm -rf "$target"; then
      echo -e "${GREEN}  [ok]     ~/.config/$name removed${RESET}"
      ((count++))
    else
      echo -e "${RED}  [fail]   ~/.config/$name${RESET}"
      ((errors++))
    fi
  done
  if [[ $errors -eq 0 ]]; then
    echo -e "${GREEN}==> Done. $count pasta(s) remooved(s).${RESET}"
  else
    echo -e "${RED}==> Finished with $errors error(s).${RESET}"
    return 1
  fi
}

install_flatpak_apps() {
    local FLATPAK=(
        com.github.zocker_160.SyncThingy
    )

    if ! command -v flatpak &>/dev/null; then
        echo "Flatpak não encontrado. Instalando..."
        sudo pacman -S --needed flatpak
    fi

    if ! flatpak remote-list | awk '{print $1}' | grep -qx "flathub"; then
        echo "Adicionando Flathub..."
        flatpak remote-add --if-not-exists \
            flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    fi

    if ((${#FLATPAK[@]} > 0)); then
        flatpak install -y flathub "${FLATPAK[@]}"
    fi
}

install_apps() {
    local PACMAN=(
        discord
    )

    local AUR=(
        pear-desktop-bin
        visual-studio-code-bin
    )

    if grep -q '^\[cachyos\]' /etc/pacman.conf; then
        PACMAN+=(
            brave
        )
    else
        AUR+=(
            brave-bin
        )
    fi

    sudo pacman -S --needed "${PACMAN[@]}"

    if ((${#AUR[@]} > 0)); then
        yay -S --needed "${AUR[@]}"
    fi

    install_flatpak_apps
}
