#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/config"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

DISTRO=""

detect_distro() {
  if [[ ! -f /etc/os-release ]]; then
    echo -e "${RED}==> Cannot detect the distribution (/etc/os-release missing).${RESET}"
    exit 1
  fi

  source /etc/os-release

  if [[ "$ID" == "arch" || "$ID_LIKE" == *"arch"* ]]; then
    DISTRO="arch"
    echo -e "${GREEN}==> Arch-based system detected: ${PRETTY_NAME:-$ID}${RESET}"

    if [[ ! -f "$CONFIG_DIR/arch/arch.sh" ]]; then
      echo -e "${RED}==> Could not find $CONFIG_DIR/arch/arch.sh${RESET}"
      exit 1
    fi
    source "$CONFIG_DIR/arch/arch.sh"

  elif [[ "$ID" == "fedora" || "$ID_LIKE" == *"fedora"* ]]; then
    DISTRO="fedora"
    echo -e "${GREEN}==> Fedora-based system detected: ${PRETTY_NAME:-$ID}${RESET}"

    if [[ ! -f "$CONFIG_DIR/fedora/fedora.sh" ]]; then
      echo -e "${RED}==> Could not find $CONFIG_DIR/fedora/fedora.sh${RESET}"
      exit 1
    fi
    source "$CONFIG_DIR/fedora/fedora.sh"

  else
    echo -e "${RED}==> Unsupported distribution. Detected: ${PRETTY_NAME:-$ID}${RESET}"
    exit 1
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
  echo -e "  ${GREEN}4)${RESET} Remove dependencies"
  echo -e "  ${GREEN}5)${RESET} Remove configs"
  echo -e "  ${GREEN}6)${RESET} Install apps"
  echo -e "  ${GREEN}7)${RESET} Setup autologin"
  echo -e "  ${GREEN}8)${RESET} Remove autologin"
  echo -e "  ${GREEN}q)${RESET} Quit"
  echo ""
}

main() {
  clear
  show_banner
  detect_distro
  echo ""

  show_menu
  read -rp "==> Option: " choice
  echo ""

  case "$choice" in
    1) install_deps  || exit 1; copy_dotfiles   || exit 1 ;;
    2) copy_dotfiles || exit 1 ;;
    3) install_deps  || exit 1 ;;
    4) remove_dependencies || exit 1 ;;
    5) remove_files  || exit 1 ;;
    6) install_apps  || exit 1 ;;
    7) configure_autologin || exit 1 ;;
    8) remove_autologin    || exit 1 ;;
    q|Q)
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

main "$@"
