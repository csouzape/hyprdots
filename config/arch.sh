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
    mpv
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
  local SRC="$SCRIPT_DIR" # arch/ dir, since SCRIPT_DIR is set in arch.sh
  local CONFIG="$HOME/.config"

  # Collect all config dirs (everything in arch/ except arch.sh itself)
  local dirs=()
  while IFS= read -r -d '' dir; do
    dirs+=("$(basename "$dir")")
  done < <(find "$SRC" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)

  if [[ ${#dirs[@]} -eq 0 ]]; then
    echo "==> No config directories found in $SRC"
    return 1
  fi

  echo "==> Config directories to copy: ${dirs[*]}"
  echo ""

  local all_existing=()
  local all_missing=()

  # Per-dir file check
  for dir in "${dirs[@]}"; do
    local src_dir="$SRC/$dir"
    local dest_dir="$CONFIG/$dir"

    while IFS= read -r -d '' file; do
      local rel="${file#"$src_dir/"}"
      if [[ -e "$dest_dir/$rel" ]]; then
        all_existing+=("$dir/$rel")
      else
        all_missing+=("$dir/$rel")
      fi
    done < <(find "$src_dir" -type f -print0 | sort -z)
  done

  # Report
  if [[ ${#all_existing[@]} -gt 0 ]]; then
    echo "==> Already exists:"
    for f in "${all_existing[@]}"; do
      echo "    [exists]  ~/.config/$f"
    done
    echo ""
  fi

  if [[ ${#all_missing[@]} -gt 0 ]]; then
    echo "==> Will be created:"
    for f in "${all_missing[@]}"; do
      echo "    [new]     ~/.config/$f"
    done
    echo ""
  fi

  # Decide whether to prompt
  if [[ ${#all_existing[@]} -gt 0 ]]; then
    read -rp "==> Some files already exist. Overwrite? (y/n): " answer
    [[ "$answer" != "y" ]] && {
      echo "Skipping dotfiles."
      return 0
    }
  fi

  # Copy
  echo "==> Copying dotfiles..."
  local errors=0

  for dir in "${dirs[@]}"; do
    local src_dir="$SRC/$dir"
    local dest_dir="$CONFIG/$dir"

    while IFS= read -r -d '' file; do
      local rel="${file#"$src_dir/"}"
      local dest_file="$dest_dir/$rel"

      mkdir -p "$(dirname "$dest_file")"
      if cp "$file" "$dest_file"; then
        echo "  [copied]  ~/.config/$dir/$rel"
      else
        echo "  [failed]  ~/.config/$dir/$rel"
        ((errors++))
      fi
    done < <(find "$src_dir" -type f -print0 | sort -z)
  done

  if [[ $errors -eq 0 ]]; then
    echo ""
    echo "==> Dotfiles copied successfully."
  else
    echo ""
    echo "==> Done with $errors error(s)."
    return 1
  fi
}

# Only run directly, not when sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  install_hyprland
  copy_dotfiles
fi

