#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
RESET='\033[0m'

detect_distro() {
    [[ "$OSTYPE" != "linux-gnu"* ]] && { echo "Unsupported OS: $OSTYPE"; exit 1; }
    [[ -f /etc/os-release ]] || { echo "/etc/os-release not found"; exit 1; }
    . /etc/os-release
}

load_distro() {
    detect_distro
    case "$ID" in
        arch)   source "$SCRIPT_DIR/distro/arch/arch.sh" ;;
        fedora) source "$SCRIPT_DIR/distro/fedora/fedora.sh" ;;
        *)      echo "Unsupported distro: $ID"; exit 1 ;;
    esac
}

require_fn() {
    declare -f "$1" &>/dev/null || { echo "Error: function '$1' not defined after sourcing distro script."; exit 1; }
}

print_banner() {
    echo -e "${CYAN}${BOLD}"
    echo -e "██╗  ██╗ ██╗   ██╗ ██████╗  ██████╗   ██████╗    ██████╗  ████████╗ ███████╗"
    echo -e "██║  ██║ ╚██╗ ██╔╝ ██╔══██╗ ██╔══██╗  ██╔══██╗  ██╔═══██╗ ╚══██╔══╝ ██╔════╝"
    echo -e "███████║  ╚████╔╝  ██████╔╝ ██████╔╝  ██║  ██║  ██║   ██║    ██║    ███████╗"
    echo -e "██╔══██║   ╚██╔╝   ██╔═══╝  ██╔══██╗  ██║  ██║  ██║   ██║    ██║    ╚════██║"
    echo -e "██║  ██║    ██║    ██║      ██║  ██║  ██████╔╝  ╚██████╔╝    ██║    ███████║"
    echo -e "╚═╝  ╚═╝    ╚═╝    ╚═╝      ╚═╝  ╚═╝  ╚═════╝    ╚═════╝     ╚═╝    ╚══════╝"
    echo -e "${RESET}"
}

main() {
    load_distro  # detect once at startup

    while true; do
        clear
        print_banner

        echo -e "  ${MAGENTA}${BOLD}[1]${RESET} Install Hyprland"
        echo -e "  ${MAGENTA}${BOLD}[2]${RESET} Copy dotfiles"
        echo -e "  ${MAGENTA}${BOLD}[3]${RESET} Exit"
        echo ""
        read -rp "  Select an option: " option

        case "$option" in
            1)
                require_fn install_hyprland
                install_hyprland
                read -rp "  Press Enter to continue..."
                ;;
            2)
                require_fn copy_dotfiles
                copy_dotfiles
                read -rp "  Press Enter to continue..."
                ;;
            3) exit 0 ;;
            *) echo "  Invalid option."; sleep 1 ;;
        esac
    done
}

main