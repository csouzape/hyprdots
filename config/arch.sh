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

    echo -e "${BLUE}==> Checking flatpak installation${RESET}"
    if ! command -v flatpak &>/dev/null; then
        echo -e "${YELLOW}  [missing] flatpak not found, installing...${RESET}"
        if sudo pacman -S --needed flatpak; then
            echo -e "${GREEN}  [ok]      flatpak installed${RESET}"
        else
            echo -e "${RED}  [fail]    could not install flatpak${RESET}"
            return 1
        fi
    else
        echo -e "${GREEN}  [ok]      flatpak already installed${RESET}"
    fi

    echo -e "${BLUE}==> Checking Flathub remote${RESET}"
    if ! flatpak remote-list | awk '{print $1}' | grep -qx "flathub"; then
        echo -e "${YELLOW}  [missing] flathub remote not found, adding...${RESET}"
        if flatpak remote-add --if-not-exists \
            flathub https://dl.flathub.org/repo/flathub.flatpakrepo; then
            echo -e "${GREEN}  [ok]      flathub remote added${RESET}"
        else
            echo -e "${RED}  [fail]    could not add flathub remote${RESET}"
            return 1
        fi
    else
        echo -e "${GREEN}  [ok]      flathub remote already configured${RESET}"
    fi

    echo -e "${BLUE}==> Installing flatpak apps${RESET}"
    if ((${#FLATPAK[@]} > 0)); then
        echo -e "${CYAN}  apps: ${FLATPAK[*]}${RESET}"
        if flatpak install -y flathub "${FLATPAK[@]}"; then
            echo -e "${GREEN}  [ok]      ${#FLATPAK[@]} app(s) installed${RESET}"
        else
            echo -e "${RED}  [fail]    error installing flatpak apps${RESET}"
            return 1
        fi
    else
        echo -e "${YELLOW}  [skip]    no flatpak apps to install${RESET}"
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

    echo -e "${BLUE}==> Resolving browser package (brave)${RESET}"
    if grep -q '^\[cachyos\]' /etc/pacman.conf; then
        echo -e "${CYAN}  [cachyos] repo detected, using pacman package${RESET}"
        PACMAN+=(
            brave
        )
    else
        echo -e "${CYAN}  [aur]     cachyos repo not found, using AUR package${RESET}"
        AUR+=(
            brave-bin
        )
    fi

    echo -e "${BLUE}==> Installing pacman apps${RESET}"
    echo -e "${CYAN}  apps: ${PACMAN[*]}${RESET}"
    if sudo pacman -S --needed "${PACMAN[@]}"; then
        echo -e "${GREEN}  [ok]      pacman apps installed${RESET}"
    else
        echo -e "${RED}  [fail]    error installing pacman apps${RESET}"
        return 1
    fi

    echo -e "${BLUE}==> Installing AUR apps${RESET}"
    if ((${#AUR[@]} > 0)); then
        echo -e "${CYAN}  apps: ${AUR[*]}${RESET}"
        if yay -S --needed "${AUR[@]}"; then
            echo -e "${GREEN}  [ok]      AUR apps installed${RESET}"
        else
            echo -e "${RED}  [fail]    error installing AUR apps${RESET}"
            return 1
        fi
    else
        echo -e "${YELLOW}  [skip]    no AUR apps to install${RESET}"
    fi

    install_flatpak_apps
}

configure_autologin() {
  local user
  user="${SUDO_USER:-$USER}"

  if [[ -z "$user" || "$user" == "root" ]]; then
    echo -e "${RED}==> Could not determine a non-root user for autologin.${RESET}"
    return 1
  fi

  if ! command -v sddm &>/dev/null && [[ ! -d /etc/sddm.conf.d ]]; then
    echo -e "${RED}==> SDDM not found on this system.${RESET}"
    return 1
  fi

  local session_dir="/usr/share/wayland-sessions"
  local session=""

  if [[ -f "$session_dir/hyprland.desktop" ]]; then
    session="hyprland"
  elif [[ -f "$session_dir/hyprland-uwsm.desktop" ]]; then
    session="hyprland-uwsm"
  else
    echo -e "${RED}==> No Hyprland session found in $session_dir.${RESET}"
    return 1
  fi

  echo -e "${BLUE}==> Configuring SDDM autologin${RESET}"
  echo -e "${CYAN}  user:    $user${RESET}"
  echo -e "${CYAN}  session: $session${RESET}"

  sudo mkdir -p /etc/sddm.conf.d || return 1

  if sudo tee /etc/sddm.conf.d/autologin.conf >/dev/null <<EOF
[Autologin]
User=$user
Session=$session
EOF
  then
    echo -e "${GREEN}==> Autologin configured for '$user' on '$session'.${RESET}"
  else
    echo -e "${RED}==> Failed to write autologin config.${RESET}"
    return 1
  fi
}
