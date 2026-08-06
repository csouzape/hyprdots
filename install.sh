#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/config"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

if [[ ! -f "$CONFIG_DIR/arch.sh" ]]; then
  echo "==> Could not find $CONFIG_DIR/arch.sh"
  exit 1
fi

source "$CONFIG_DIR/arch.sh"

check_arch_base() {
  if [[ ! -f /etc/os-release ]]; then
    echo -e "${RED}==> Cannot detect the distribution (/etc/os-release missing).${RESET}"
    exit 1
  fi

  source /etc/os-release

  if [[ "$ID" == "arch" || "$ID_LIKE" == *"arch"* ]]; then
    echo -e "${GREEN}==> Arch-based system detected: ${PRETTY_NAME:-$ID}${RESET}"
  else
    echo -e "${RED}==> This script only supports Arch-based distributions. Detected: ${PRETTY_NAME:-$ID}${RESET}"
    exit 1
  fi
}

check_multilib() {
    if grep -q "^\[multilib\]" /etc/pacman.conf; then
        echo -e "${GREEN}==> Multilib already enabled.${RESET}"
        return 0
    fi

    echo -e "${YELLOW}==> Enabling multilib repository...${RESET}"
    sudo sed -i '/^#\[multilib\]/,/^#Include/ s/^#//' /etc/pacman.conf
    sudo pacman -Sy
}

check_aur() {
    if command -v yay &> /dev/null; then
        echo -e "${BLUE}==> AUR helper detected.${RESET}"
    else
        read -rp "==> No AUR helper detected. Do you want to install one? (y/n): " install_aur
        if [[ "$install_aur" =~ ^[Yy]$ ]]; then
            echo -e "${CYAN}==> Installing yay AUR helper...${RESET}"
            sudo pacman -S --needed git base-devel || return 1

            local tmpdir
            tmpdir=$(mktemp -d)
            trap 'rm -rf "$tmpdir"' RETURN

            git clone https://aur.archlinux.org/yay.git "$tmpdir/yay" || return 1
            (cd "$tmpdir/yay" && makepkg -si) || return 1

            echo -e "${GREEN}==> yay installed successfully.${RESET}"
        else
            echo -e "${YELLOW}==> Skipping AUR helper installation.${RESET}"
        fi
    fi
}


show_banner() {
  echo -e "${CYAN}"
  cat <<'EOF'
██╗  ██╗██╗   ██╗██████╗ ██████╗ ██████╗  ██████╗ ████████╗███████╗
██║  ██║╚██╗ ██╔╝██╔══██╗██╔══██╗██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝
███████║ ╚████╔╝ ██████╔╝██████╔╝██║  ██║██║   ██║   ██║   ███████╗
██╔══██║  ╚██╔╝  ██╔═══╝ ██╔══██╗██║  ██║██║   ██║   ██║   ╚════██║
██║  ██║   ██║   ██║     ██║  ██║██████╔╝╚██████╔╝   ██║   ███████║
╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚═╝  ╚═╝╚═════╝  ╚═════╝    ╚═╝   ╚══════╝
EOF
  echo -e "${RESET}"
}

show_menu() {
  echo -e "${YELLOW}Choose an option:${RESET}"
  echo -e "  ${GREEN}1)${RESET} Install dependencies ${BLUE}+${RESET} copy configs"
  echo -e "  ${GREEN}2)${RESET} Only copy configs"
  echo -e "  ${GREEN}3)${RESET} Only install dependencies"
  echo -e "  ${GREEN}4)${RESET} Remove Dependencies"
  echo -e "  ${GREEN}5)${RESET} Remove Configs"
  echo -e "  ${GREEN}q)${RESET} Quit"
  echo ""
}

install_deps() {
  check_arch_base
  check_multilib
  check_aur || return 1
  install_pacman_dependences || return 1
}

main() {
  clear
  show_banner

  show_menu
  read -rp "==> Option: " choice
  echo ""

  case "$choice" in
    1)
      install_deps || exit 1
      copy_dotfiles || exit 1
      install_systemd_services || exit 1
      ;;
    2)
      copy_dotfiles || exit 1
      install_systemd_services || exit 1
      ;;
    3)
      install_deps || exit 1
      ;;
    4)
      remove_systemd_services
      remove_aur_dependences || exit 1
      remove_dependencies || exit 1
      ;;
    5)
      remove_systemd_services
      remove_files || exit 1
      ;;
    q | Q)
      echo -e "${YELLOW}==> Aborted.${RESET}"
      exit 0
      ;;
    *)
      echo -e "${RED}==> Invalid option.${RESET}"
      exit 1
      ;;
  esac

  echo -e "${GREEN}==> All done!${RESET}"
}
