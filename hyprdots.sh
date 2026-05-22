#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
RESET='\033[0m'

distro() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
    else
        echo "Cannot determine Linux distribution: /etc/os-release not found."
        exit 1
    fi
}

load_distro() {
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        echo "Unsupported operating system: $OSTYPE"
        exit 1
    fi

    distro

    case "$ID" in
        arch)
            source "$SCRIPT_DIR/distro/arch/arch.sh"
            ;;
        fedora)
            source "$SCRIPT_DIR/distro/fedora/fedora.sh"
            ;;
        *)
            echo "Unsupported Linux distribution: $ID"
            exit 1
            ;;
    esac
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
                echo "Running install_hyprland..."
                load_distro
                install_hyprland
                read -rp "Press Enter..."
                ;;
            2)
                echo "Running copy_dotfiles..."
                load_distro
                copy_dotfiles
                read -rp "Press Enter..."
                ;;
            3)
                exit 0
                ;;
            *)
                echo "Invalid option."
                sleep 1
                ;;
        esac
    done
}

main