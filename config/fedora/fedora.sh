#!/bin/bash
FEDORA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

LOCKFILE="/tmp/hyprdots-fedora.lock"
exec 9>"$LOCKFILE"
if ! flock -n 9; then
  echo -e "${RED}==>  There is already an instance of this script running.(lock: $LOCKFILE).${RESET}"
  echo -e "${YELLOW}==>  If you are certain that no other instance is running: rm -f $LOCKFILE${RESET}"
  exit 1
fi

DNF_OPTS=(-y --setopt=timeout=30)

_DNF_BASE=(
  hyprland
  waybar
  sddm
  SwayNotificationCenter
  swaybg
  alacritty
  rofi
  jq
  libnotify
  wireplumber
  Thunar
  tumbler
  imv
  mpv
  grim
  slurp
  wl-clipboard
  xdg-desktop-portal
  xdg-desktop-portal-hyprland
  xdg-desktop-portal-gtk
  pavucontrol
  nwg-look
  fzf
  jetbrains-mono-fonts-all
  google-roboto-fonts
  git
  meson
  sassc
  gtk3-devel
  gtk4-devel
)

_DNF_APPS=(
  discord
  obs-studio
)

_FLATPAK_APPS=(
  com.github.zocker_160.SyncThingy
  md.obsidian.Obsidian
  com.visualstudio.code
  io.github.zen_browser.zen
)

enable_hyprland_stack() {
  local repos=(
    "ashbuk/Hyprland-Fedora"
    "tofik/nwg-shell"
  )

  for repo in "${repos[@]}"; do
    local copr_id="copr:copr.fedorainfracloud.org:${repo//\//:}"
    if dnf repolist --enabled 2>/dev/null | grep -q "$copr_id"; then
      echo -e "${GREEN}  [ok]     COPR already enabled: $repo${RESET}"
    else
      echo -e "${CYAN}  [+]      Enabling COPR: $repo${RESET}"
      sudo dnf copr enable -y "$repo" || return 1
    fi
  done
}

check_rpmfusion() {
  if rpm -q rpmfusion-free-release &>/dev/null && rpm -q rpmfusion-nonfree-release &>/dev/null; then
    echo -e "${GREEN}==> RPM Fusion already enabled.${RESET}"
    return 0
  fi

  echo -e "${YELLOW}==> Enabling RPM Fusion...${RESET}"
  sudo dnf install "${DNF_OPTS[@]}" \
    "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
    "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
}

_fzf_select() {
  local header="$1"; shift
  local -a items=("$@")

  if ! command -v fzf &>/dev/null; then
    echo -e "${YELLOW}==> fzf not found. Installing...${RESET}"
    sudo dnf install "${DNF_OPTS[@]}" fzf
  fi

  printf '%s\n' "${items[@]}" \
    | fzf --multi \
          --header="$header" \
          --prompt="HYPRDOTS Fedora › " \
          --marker="✓" \
          --pointer="▶" \
          --preview='dnf info {} 2>/dev/null || flatpak info {} 2>/dev/null || echo "No info"' \
          --preview-window=right:40%
}

install_dnf_dependences() {
  echo -e "${BLUE}==> Enabling COPRs...${RESET}"
  enable_hyprland_stack || return 1

  echo -e "${BLUE}==> Installing base DNF packages...${RESET}"
  sudo dnf install "${DNF_OPTS[@]}" "${_DNF_BASE[@]}" || return 1
}

install_deps() {
  check_rpmfusion
  install_dnf_dependences   || return 1
  install_waypaper          || return 1
  install_materia_gtk_theme || return 1
}

install_waypaper() {
  if command -v waypaper &>/dev/null; then
    echo -e "${GREEN}==> waypaper already installed ($(waypaper --version 2>/dev/null || true)).${RESET}"
    return 0
  fi

  echo -e "${BLUE}==> Installing waypaper via pip...${RESET}"

  if ! command -v pip3 &>/dev/null; then
    sudo dnf install "${DNF_OPTS[@]}" python3-pip || return 1
  fi

  pip3 install --user waypaper --break-system-packages || return 1

  export PATH="$HOME/.local/bin:$PATH"

  echo -e "${GREEN}  [ok]     waypaper installed.${RESET}"
}

install_materia_gtk_theme() {
  local repo_dir="$HOME/.local/src/materia-gtk-theme"
  local repo_url="https://github.com/nana-4/materia-theme.git"

  echo -e "${BLUE}==> Materia GTK Theme${RESET}"

  # meson.build baixa/compila dart-sass via npm quando o binário "sass" não
  # está no PATH — sem npm o "meson setup" falha em tempo de configuração.
  if ! command -v npm &>/dev/null; then
    echo -e "${CYAN}  [deps]    Installing npm (required by meson.build)...${RESET}"
    sudo dnf install "${DNF_OPTS[@]}" npm || return 1
  fi

  if [[ -d "$repo_dir/.git" ]]; then
    echo -e "${CYAN}  [update]  Pulling latest changes...${RESET}"
    git -C "$repo_dir" pull --ff-only || return 1
  else
    echo -e "${CYAN}  [clone]   $repo_url${RESET}"
    mkdir -p "$(dirname "$repo_dir")"
    git clone "$repo_url" "$repo_dir" || return 1
  fi

  cd "$repo_dir" || return 1

  # Remove build dir anterior se existir
  [[ -d build ]] && rm -rf build

  echo -e "${CYAN}  [meson]   Configuring...${RESET}"
  # gnome_shell_version informado manualmente — não requer gnome-shell instalado
  meson setup build -Dgnome_shell_version=47 || return 1

  echo -e "${CYAN}  [compile] Building...${RESET}"
  meson compile -C build || return 1

  echo -e "${CYAN}  [install] Installing to /usr/share/themes...${RESET}"
  sudo meson install -C build || return 1

  echo -e "${GREEN}  [ok]      Materia GTK Theme installed.${RESET}"
  cd - >/dev/null
}

# ── Instalação de apps opcionais ────────────────────────────────────────────────

install_apps() {
  local -a dnf_sel flatpak_sel

  echo -e "${CYAN}==> Select DNF apps to install (TAB to mark, ENTER to confirm):${RESET}"
  mapfile -t dnf_sel < <(_fzf_select "HYPRDOTS Fedora — DNF apps" "${_DNF_APPS[@]}")

  echo -e "${CYAN}==> Select Flatpak apps to install (TAB to mark, ENTER to confirm):${RESET}"
  mapfile -t flatpak_sel < <(_fzf_select "HYPRDOTS Fedora — Flatpak apps" "${_FLATPAK_APPS[@]}")

  if ((${#dnf_sel[@]} > 0)); then
    echo -e "${BLUE}==> Installing DNF apps: ${dnf_sel[*]}${RESET}"
    sudo dnf install "${DNF_OPTS[@]}" "${dnf_sel[@]}" || return 1
  else
    echo -e "${YELLOW}==> No DNF apps selected.${RESET}"
  fi

  if ((${#flatpak_sel[@]} > 0)); then
    _ensure_flatpak || return 1
    echo -e "${BLUE}==> Installing Flatpak apps: ${flatpak_sel[*]}${RESET}"
    flatpak install -y flathub "${flatpak_sel[@]}" || return 1
  else
    echo -e "${YELLOW}==> No Flatpak apps selected.${RESET}"
  fi
}

_ensure_flatpak() {
  if ! command -v flatpak &>/dev/null; then
    echo -e "${YELLOW}==> Installing flatpak...${RESET}"
    sudo dnf install "${DNF_OPTS[@]}" flatpak || return 1
  fi
  if ! flatpak remote-list | awk '{print $1}' | grep -qx "flathub"; then
    echo -e "${YELLOW}==> Adding flathub remote...${RESET}"
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || return 1
  fi
}

copy_dotfiles() {
  local SRC="$FEDORA_DIR"
  local DEST="$HOME/.config"

  echo -e "${BLUE}==> Copying configs to $DEST${RESET}"
  mkdir -p "$DEST"

  local errors=0 count=0
  for dir in "$SRC"/*/; do
    [[ -d "$dir" ]] || continue
    local name; name="$(basename "$dir")"
    [[ "$name" == "fedora.sh" ]] && continue

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

remove_dependencies() {
  local PACKAGES=(
    hyprland waybar SwayNotificationCenter swaybg alacritty rofi
    grim slurp imv Thunar
  )

  local removable=()
  for pkg in "${PACKAGES[@]}"; do
    rpm -q "$pkg" &>/dev/null && removable+=("$pkg") || \
      echo -e "${YELLOW}  [skip]   $pkg not installed${RESET}"
  done

  ((${#removable[@]} == 0)) && { echo -e "${YELLOW}==> Nothing to remove.${RESET}"; return 0; }

  echo -e "${BLUE}==> Removing: ${removable[*]}${RESET}"
  sudo dnf remove -y "${removable[@]}" || return 1
}

remove_files() {
  local SRC="$FEDORA_DIR"
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
