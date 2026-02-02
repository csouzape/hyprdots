#!/bin/bash
set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to detect the Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    elif [ -f /etc/arch-release ]; then
        DISTRO="arch"
    elif [ -f /etc/fedora-release ]; then
        DISTRO="fedora"
    else
        DISTRO="unknown"
    fi
    echo "$DISTRO"
}

# Function to check if script exists
check_script() {
    local script_path="$1"
    if [ ! -f "$script_path" ]; then
        echo -e "${RED}Error: Script not found: $script_path${RC}"
        exit 1
    fi
    
    # Make script executable
    chmod +x "$script_path"
}

# Function to copy distro-specific dotfiles
copy_distro_dotfiles() {
    local distro="$1"
    local source_dir="$SCRIPT_DIR/distro/$distro"
    local install_user="${SUDO_USER:-$USER}"
    local user_home=$(eval echo ~$install_user)
    
    if [ -d "$source_dir" ]; then
        echo -e "${YELLOW}Copying $distro-specific dotfiles...${RC}"
        sudo -u $install_user mkdir -p "$user_home/.config"
        sudo -u $install_user cp -r "$source_dir/"* "$user_home/.config/" 2>/dev/null || true
        echo -e "${GREEN}Distro-specific dotfiles copied${RC}"
    else
        echo -e "${YELLOW}No distro-specific dotfiles found for $distro${RC}"
    fi
}

# Main function
main() {
    echo -e "${BLUE}========================================${RC}"
    echo -e "${BLUE}       Hyprdots Installation Script    ${RC}"
    echo -e "${BLUE}========================================${RC}"
    echo ""
    
    # Check if running as root
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Please run this script with sudo${RC}"
        exit 1
    fi
    
    # Detect distribution
    DISTRO=$(detect_distro)
    echo -e "${BLUE}Detected distribution: ${YELLOW}$DISTRO${RC}"
    echo ""
    
    # Determine which installation script to run
    case "$DISTRO" in
        arch|archarm|manjaro|endeavouros)
            INSTALL_SCRIPT="$SCRIPT_DIR/distro/arch/arch.sh"
            echo -e "${GREEN}Using Arch Linux installation script${RC}"
            ;;
        fedora)
            INSTALL_SCRIPT="$SCRIPT_DIR/distro/fedora/fedora.sh"
            echo -e "${GREEN}Using Fedora installation script${RC}"
            ;;
        *)
            echo -e "${RED}Unsupported distribution: $DISTRO${RC}"
            echo -e "${YELLOW}Supported distributions: Arch Linux, Fedora${RC}"
            exit 1
            ;;
    esac
    
    # Check if installation script exists
    check_script "$INSTALL_SCRIPT"
    
    # Run the installation script
    echo -e "${YELLOW}Starting installation...${RC}"
    echo ""
    bash "$INSTALL_SCRIPT"
    
    # Copy distro-specific dotfiles after installation
    copy_distro_dotfiles "$DISTRO"
    
    echo ""
    echo -e "${GREEN}========================================${RC}"
    echo -e "${GREEN}   Installation completed successfully!${RC}"
    echo -e "${GREEN}========================================${RC}"
}

main