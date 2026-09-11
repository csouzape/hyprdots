#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
install_pacman_dependences() {
  local PACMAN=(
    hyprland
    waybar
    sddm
    swaync
    swaybg
    alacritty
    rofi
    jq
    libnotify
    wireplumber
    qt5ct
    thunar
    gvfs
    thunar-volman
    tumbler
    ffmpegthumbnailer
    imv
    mpv
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
    pacman-contrib
    nwg-look
    materia-gtk-theme
  )
  echo "==> Installing pacman packages..."
  sudo pacman -S --needed "${PACMAN[@]}" || return 1
}


install_aur_dependences() {
  local AUR=(
    waypaper
  )

  if ! command -v yay &>/dev/null; then
    echo -e "${RED}==> yay is required to install AUR packages.${RESET}"
    return 1
  fi

  echo "==> Installing AUR packages..."
  yay -S --needed "${AUR[@]}" || return 1
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
  local HYPRLAND_PACKAGES=(
    hyprland
    hyprpolkitagent
    xdg-desktop-portal-hyprland
    waybar
    swaync
    swaybg
    alacritty
    rofi
    waypaper
    grim
    slurp
    imv
    thunar
    thunar-volman
  )

  local installed=()
  local missing=()
  local package

  for package in "${HYPRLAND_PACKAGES[@]}"; do
    if pacman -Q "$package" &>/dev/null; then
      installed+=("$package")
    else
      missing+=("$package")
    fi
  done

  if ((${#missing[@]} > 0)); then
    echo -e "${YELLOW}==> Packages not installed: ${missing[*]}${RESET}"
    read -rp "==> Do you want to continue anyway? (y/n): " skip_missing
    if [[ ! "$skip_missing" =~ ^[Yy]$ ]]; then
      echo -e "${YELLOW}==> Removal cancelled.${RESET}"
      return 1
    fi
  fi

  if ((${#installed[@]} == 0)); then
    echo -e "${YELLOW}==> No listed packages are installed. Skipping removal.${RESET}"
    return 0
  fi

  if ! command -v pactree &>/dev/null; then
    echo -e "${RED}==> pactree was not found. Install pacman-contrib first.${RESET}"
    return 1
  fi

  local -A targets=()
  local -A blocked=()
  local -A dependents=()
  local dependent

  for package in "${installed[@]}"; do
    targets["$package"]=1
  done

  for package in "${installed[@]}"; do
    while read -r dependent; do
      [[ -z "$dependent" || "$dependent" == "$package" ]] && continue
      [[ -n "${targets[$dependent]+x}" ]] && continue

      if pacman -Qi "$dependent" 2>/dev/null | awk -v target="$package" '
        /^Depends On/ {
          in_depends = 1
          sub(/^[^:]*:[[:space:]]*/, "")
        }
        /^Optional Deps/ { in_depends = 0 }
        in_depends {
          for (field_index = 1; field_index <= NF; field_index++) {
            dependency = $field_index
            sub(/[<>=].*$/, "", dependency)
            if (dependency == target) found = 1
          }
        }
        END { exit !found }
      '; then
        blocked["$package"]=1
        dependents["$package"]+=" $dependent"
      fi
    done < <(pactree -r -u -l "$package" 2>/dev/null)
  done

  local removable=()
  for package in "${installed[@]}"; do
    if [[ -n "${blocked[$package]+x}" ]]; then
      echo -e "${YELLOW}  [skip]   $package is required by:${dependents[$package]}${RESET}"
    else
      removable+=("$package")
    fi
  done

  if ((${#removable[@]} == 0)); then
    echo -e "${YELLOW}==> No Hyprland packages can be removed without affecting other packages.${RESET}"
    return 0
  fi

  echo -e "${BLUE}==> Removing Hyprland packages without breaking other packages...${RESET}"
  sudo pacman -Rn "${removable[@]}" || return 1
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
    echo -e "${GREEN}==> Done. $count folder(s) removed.${RESET}"
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
    obsidian
    youtube-music-bin
    zed
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

  if sudo tee /etc/sddm.conf.d/autologin.conf >/dev/null <<EOF; then
[Autologin]
User=$user
Session=$session
EOF
    echo -e "${GREEN}==> Autologin configured for '$user' on '$session'.${RESET}"
  else
    echo -e "${RED}==> Failed to write autologin config.${RESET}"
    return 1
  fi
}

remove_autologin() {
  local conf="/etc/sddm.conf.d/autologin.conf"

  echo -e "${BLUE}==> Removing SDDM autologin${RESET}"

  if [[ ! -f "$conf" ]]; then
    echo -e "${YELLOW}  [skip]    autologin config not found ($conf)${RESET}"
    return 0
  fi

  if sudo rm -f "$conf"; then
    echo -e "${GREEN}  [ok]      autologin config removed${RESET}"
  else
    echo -e "${RED}  [fail]    could not remove $conf${RESET}"
    return 1
  fi
}

install_sddm_theme() {
  local SRC_CONF="$SCRIPT_DIR/sddm/sddm.conf"
  local SRC_THEME="$SCRIPT_DIR/sddm/chili"
  local DEST_THEME="/usr/share/sddm/themes/chili"

  if [[ ! -d "$SRC_THEME" ]]; then
    echo -e "${RED}  [fail]    $SRC_THEME not found in dotfiles${RESET}"
    return 1
  fi
  if [[ ! -f "$SRC_CONF" ]]; then
    echo -e "${RED}  [fail]    $SRC_CONF not found in dotfiles${RESET}"
    return 1
  fi

  echo -e "${BLUE}==> Installing Chili SDDM theme files${RESET}"
  if sudo mkdir -p "$DEST_THEME" && sudo cp -r "$SRC_THEME"/. "$DEST_THEME"/; then
    echo -e "${GREEN}  [ok]      theme files copied to $DEST_THEME${RESET}"
  else
    echo -e "${RED}  [fail]    could not copy theme files${RESET}"
    return 1
  fi

  if [[ -f /etc/sddm.conf ]]; then
    sudo cp /etc/sddm.conf /etc/sddm.conf.bak
    echo -e "${YELLOW}  [backup]  /etc/sddm.conf -> /etc/sddm.conf.bak${RESET}"
  fi

  echo -e "${BLUE}==> Applying /etc/sddm.conf from dotfiles${RESET}"
  if sudo cp "$SRC_CONF" /etc/sddm.conf; then
    echo -e "${GREEN}==> SDDM theme 'chili' configured.${RESET}"
  else
    echo -e "${RED}==> Failed to apply /etc/sddm.conf${RESET}"
    return 1
  fi

  echo -e "${BLUE}==> Enabling sddm.service${RESET}"
  sudo systemctl enable sddm.service
}
