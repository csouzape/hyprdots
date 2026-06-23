#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

install_pacman_dependences() {
  local PACMAN=(
    hyprland 
    swaync 
    swaybg 
    grim 
    slurp 
    alacritty 
    rofi 
    thunar 
    waybar 
    wl-clipboard 
    xdg-desktop-portal-hyprland 
    xdg-desktop-portal-gtk 
    pavucontrol

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