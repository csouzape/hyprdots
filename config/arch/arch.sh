#!/bin/bash
ARCH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

_PACMAN_BASE=(
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
  fzf
)


_AUR_BASE=(
  waypaper
)

_PACMAN_APPS=(
  discord
)
_AUR_APPS=(
  pear-desktop-bin
  visual-studio-code-bin
  obsidian
  youtube-music-bin
  zed
  brave-bin
)

check_multilib() {
  if grep -q "^\[multilib\]" /etc/pacman.conf; then
    echo -e "${GREEN}==> Multilib already enabled.${RESET}"
    return 0
  fi

  echo -e "${YELLOW}==> Enabling multilib repository...${RESET}"
  sudo sed -i '/^#\[multilib\]/,/^#Include/ s/^#//' /etc/pacman.conf
  sudo pacman -Sy
}

# ── AUR helper ─────────────────────────────────────────────────────────────────

check_aur() {
  if command -v yay &>/dev/null; then
    echo -e "${BLUE}==> AUR helper (yay) detected.${RESET}"
    return 0
  fi

  read -rp "==> No AUR helper detected. Install yay? (y/n): " yn
  [[ "$yn" =~ ^[Yy]$ ]] || { echo -e "${YELLOW}==> Skipping AUR helper.${RESET}"; return 1; }

  echo -e "${CYAN}==> Installing yay...${RESET}"
  sudo pacman -S --needed git base-devel || return 1

  local tmpdir
  tmpdir=$(mktemp -d)
  trap 'rm -rf "$tmpdir"' RETURN

  git clone https://aur.archlinux.org/yay.git "$tmpdir/yay" || return 1
  (cd "$tmpdir/yay" && makepkg -si)                          || return 1

  echo -e "${GREEN}==> yay installed.${RESET}"
}

# ── Seleção de pacotes com fzf ─────────────────────────────────────────────────

_fzf_select() {
  local header="$1"; shift
  local -a items=("$@")

  if ! command -v fzf &>/dev/null; then
    # fzf ainda não instalado: instala agora e seleciona tudo
    echo -e "${YELLOW}==> fzf not found. Installing...${RESET}"
    sudo pacman -S --needed fzf
  fi

  printf '%s\n' "${items[@]}" \
    | fzf --multi \
          --header="$header" \
          --prompt="HYPRDOTS Arch › " \
          --marker="✓" \
          --pointer="▶" \
          --preview='pacman -Si {} 2>/dev/null || yay -Si {} 2>/dev/null || echo "No info"' \
          --preview-window=right:40%
}

# ── Instalação de dependências ──────────────────────────────────────────────────

install_pacman_dependences() {
  echo -e "${BLUE}==> Installing base pacman packages...${RESET}"
  sudo pacman -S --needed "${_PACMAN_BASE[@]}" || return 1
}

install_aur_dependences() {
  if ! command -v yay &>/dev/null; then
    echo -e "${RED}==> yay is required to install AUR packages.${RESET}"
    return 1
  fi

  echo -e "${BLUE}==> Installing base AUR packages...${RESET}"
  yay -S --needed "${_AUR_BASE[@]}" || return 1
}

install_deps() {
  check_multilib
  install_pacman_dependences || return 1

  read -rp "==> Install AUR base packages? (y/n): " yn
  if [[ "$yn" =~ ^[Yy]$ ]]; then
    check_aur    || return 1
    install_aur_dependences || return 1
  else
    echo -e "${YELLOW}==> Skipping AUR packages.${RESET}"
  fi
}


install_apps() {
  local -a pacman_sel aur_sel

  echo -e "${CYAN}==> Select pacman apps to install (TAB to mark, ENTER to confirm):${RESET}"
  mapfile -t pacman_sel < <(_fzf_select "HYPRDOTS Arch — pacman apps" "${_PACMAN_APPS[@]}")

  if grep -q '^\[cachyos\]' /etc/pacman.conf; then
    echo -e "${CYAN}  [cachyos] repo detected — brave available via pacman${RESET}"
    _AUR_APPS=("${_AUR_APPS[@]/brave-bin}")
    _PACMAN_APPS+=(brave)
  fi

  echo -e "${CYAN}==> Select AUR apps to install (TAB to mark, ENTER to confirm):${RESET}"
  mapfile -t aur_sel < <(_fzf_select "HYPRDOTS Arch — AUR apps" "${_AUR_APPS[@]}")

  if ((${#pacman_sel[@]} > 0)); then
    echo -e "${BLUE}==> Installing pacman apps: ${pacman_sel[*]}${RESET}"
    sudo pacman -S --needed "${pacman_sel[@]}" || return 1
  else
    echo -e "${YELLOW}==> No pacman apps selected.${RESET}"
  fi

  if ((${#aur_sel[@]} > 0)); then
    check_aur || return 1
    echo -e "${BLUE}==> Installing AUR apps: ${aur_sel[*]}${RESET}"
    yay -S --needed "${aur_sel[@]}" || return 1
  else
    echo -e "${YELLOW}==> No AUR apps selected.${RESET}"
  fi

  install_flatpak_apps
}


install_flatpak_apps() {
  local -a FLATPAK=(
    com.github.zocker_160.SyncThingy
  )

  if ! command -v flatpak &>/dev/null; then
    echo -e "${YELLOW}==> flatpak not found, installing...${RESET}"
    sudo pacman -S --needed flatpak || return 1
  fi

  if ! flatpak remote-list | awk '{print $1}' | grep -qx "flathub"; then
    echo -e "${YELLOW}==> Adding flathub remote...${RESET}"
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || return 1
  fi

  echo -e "${BLUE}==> Installing flatpak apps: ${FLATPAK[*]}${RESET}"
  flatpak install -y flathub "${FLATPAK[@]}" || return 1
}

# ── Dotfiles ────────────────────────────────────────────────────────────────────

copy_dotfiles() {
  local SRC="$ARCH_DIR"
  local DEST="$HOME/.config"

  echo -e "${BLUE}==> Copying configs to $DEST${RESET}"
  mkdir -p "$DEST"

  local errors=0 count=0
  for dir in "$SRC"/*/; do
    [[ -d "$dir" ]] || continue
    local name; name="$(basename "$dir")"
    [[ "$name" == "arch.sh" ]] && continue

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

  [[ $errors -eq 0 ]] \
    && echo -e "${GREEN}==> Done. $count config(s) copied.${RESET}" \
    || { echo -e "${RED}==> Finished with $errors error(s).${RESET}"; return 1; }
}

# ── Remoção de dependências ─────────────────────────────────────────────────────

remove_aur_dependences() {
  echo -e "${YELLOW}==> Keeping yay installed. AUR helper removal is disabled for safety.${RESET}"
}

remove_dependencies() {
  local PACKAGES=(
    hyprland hyprpolkitagent xdg-desktop-portal-hyprland
    waybar swaync swaybg alacritty rofi waypaper
    grim slurp imv thunar thunar-volman
  )

  local installed=() missing=()
  for pkg in "${PACKAGES[@]}"; do
    pacman -Q "$pkg" &>/dev/null && installed+=("$pkg") || missing+=("$pkg")
  done

  if ((${#missing[@]} > 0)); then
    echo -e "${YELLOW}==> Not installed: ${missing[*]}${RESET}"
    read -rp "==> Continue anyway? (y/n): " yn
    [[ "$yn" =~ ^[Yy]$ ]] || { echo -e "${YELLOW}==> Cancelled.${RESET}"; return 1; }
  fi

  ((${#installed[@]} == 0)) && { echo -e "${YELLOW}==> Nothing to remove.${RESET}"; return 0; }

  if ! command -v pactree &>/dev/null; then
    echo -e "${RED}==> pactree not found. Install pacman-contrib first.${RESET}"
    return 1
  fi

  local -A blocked dependents
  for pkg in "${installed[@]}"; do
    while read -r dep; do
      [[ -z "$dep" || "$dep" == "$pkg" ]] && continue
      pacman -Qi "$dep" 2>/dev/null | awk -v t="$pkg" '
        /^Depends On/ { sub(/^[^:]*:[[:space:]]*/,""); in_d=1 }
        /^Optional Deps/ { in_d=0 }
        in_d { for(i=1;i<=NF;i++){ d=$i; sub(/[<>=].*/,"",d); if(d==t) f=1 } }
        END { exit !f }
      ' && { blocked[$pkg]=1; dependents[$pkg]+=" $dep"; }
    done < <(pactree -r -u -l "$pkg" 2>/dev/null)
  done

  local removable=()
  for pkg in "${installed[@]}"; do
    if [[ -n "${blocked[$pkg]+x}" ]]; then
      echo -e "${YELLOW}  [skip]   $pkg required by:${dependents[$pkg]}${RESET}"
    else
      removable+=("$pkg")
    fi
  done

  ((${#removable[@]} == 0)) && { echo -e "${YELLOW}==> Nothing can be safely removed.${RESET}"; return 0; }

  sudo pacman -Rn "${removable[@]}" || return 1
}

remove_files() {
  local SRC="$ARCH_DIR"
  local DEST="$HOME/.config"

  echo -e "${BLUE}==> Removing configs from $DEST${RESET}"
  local errors=0 count=0

  for dir in "$SRC"/*/; do
    [[ -d "$dir" ]] || continue
    local name; name="$(basename "$dir")"
    local target="$DEST/$name"

    if [[ ! -e "$target" ]]; then
      echo -e "${YELLOW}  [skip]   ~/.config/$name (not found)${RESET}"
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

  [[ $errors -eq 0 ]] \
    && echo -e "${GREEN}==> Done. $count folder(s) removed.${RESET}" \
    || { echo -e "${RED}==> Finished with $errors error(s).${RESET}"; return 1; }
}
configure_autologin() {
  local user="${SUDO_USER:-$USER}"
  [[ -z "$user" || "$user" == "root" ]] && {
    echo -e "${RED}==> Could not determine a non-root user.${RESET}"; return 1; }

  local session_dir="/usr/share/wayland-sessions"
  local session=""
  [[ -f "$session_dir/hyprland.desktop" ]]      && session="hyprland"
  [[ -f "$session_dir/hyprland-uwsm.desktop" ]] && session="hyprland-uwsm"
  [[ -z "$session" ]] && {
    echo -e "${RED}==> No Hyprland session found in $session_dir.${RESET}"; return 1; }

  echo -e "${BLUE}==> Configuring SDDM autologin: user=$user session=$session${RESET}"
  sudo mkdir -p /etc/sddm.conf.d
  sudo tee /etc/sddm.conf.d/autologin.conf >/dev/null <<EOF
[Autologin]
User=$user
Session=$session
EOF
  echo -e "${GREEN}==> Autologin configured.${RESET}"
}

remove_autologin() {
  local conf="/etc/sddm.conf.d/autologin.conf"
  if [[ ! -f "$conf" ]]; then
    echo -e "${YELLOW}==> Autologin config not found ($conf).${RESET}"
    return 0
  fi
  sudo rm -f "$conf" \
    && echo -e "${GREEN}==> Autologin config removed.${RESET}" \
    || { echo -e "${RED}==> Could not remove $conf.${RESET}"; return 1; }
}
