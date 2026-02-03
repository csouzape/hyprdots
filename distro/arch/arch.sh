#!/bin/bash
#et -e 
# Color codes for output
RED='\034[0;31m'
GREEN='\034[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RC='\033[0m'

# get the user who invoked sudo 
INSTALL_USER=${SUDO_USER:-$USER}
USER_HOME=$(eval echo ~$INSTALL_USER)

# pacman flags 
flags="-S -q --needed --noconfirm --noprogressbar"


#call for root permission
root_permission() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Please run as root or with sudo${RC}"
        exit 1
    fi
    echo -e "${GREEN}Running with root privileges${RC}"
}


# install yay
install_yay() {
    echo -e "${YELLOW}Installing yay...${RC}"
    pacman -S --noconfirm --needed git base-devel
    
    # Install as regular user
    cd /tmp
    sudo -u $INSTALL_USER git clone https://aur.archlinux.org/yay.git
    cd yay 
    sudo -u $INSTALL_USER makepkg -si --noconfirm
    cd ..
    rm -rf yay
    echo -e "${GREEN}yay installed successfully${RC}"
}

check_yay() {
    if ! command -v yay &> /dev/null; then
        echo -e "${YELLOW}yay could not be found, installing...${RC}"
        install_yay
    else
        echo -e "${GREEN}yay is already installed${RC}"
    fi
}
# enable multilib repository function
install_multilib() {
    echo -e "${YELLOW}Enabling multilib repository...${RC}"
    sed -i '/\[multilib\]/,/Include = \/etc\/pacman.d\/mirrorlist/s/^#//' /etc/pacman.conf
    pacman -Syu --noconfirm
    echo -e "${GREEN}Multilib repository enabled${RC}"
}

# tlp configuration function
configure_tlp() {
    echo -e "${YELLOW}Configuring TLP for power management...${RC}"
    pacman $flags tlp tlp-rdw
    systemctl enable tlp
    systemctl start tlp
    echo -e "${GREEN}TLP has been configured and started${RC}"
}
# install pacman dependencies function
install_dependencies_aur() {
    echo -e "${YELLOW}Installing AUR dependencies for Hyprland...${RC}"
    sudo -u $INSTALL_USER yay -S --noconfirm waypaper google-chrome-bin
    echo -e "${GREEN}AUR dependencies installed${RC}"
}

install_dependencies_pacman(){
    echo -e "${YELLOW} Installing pacman dependences ${RC}"
    pacman $flags hyprland swww sddm alacritty thunar pavucontrol ttf-jetbrains-mono waybar discord xdg-desktop-portal \
        xdg-desktop-portal-hyprland hyprshot mako 
}


auto_login() {
    echo -e "${YELLOW}Setting up auto-login for user $INSTALL_USER...${RC}"
    mkdir -p /etc/sddm.conf.d
    cat > /etc/sddm.conf.d/autologin.conf <<EOF
[Autologin]
User=$INSTALL_USER
Session=hyprland
EOF
    echo -e "${GREEN}Auto-login configured for user $INSTALL_USER${RC}"
}
# install pacman dependencies function
gaming_dependencies() {
    echo -e "${YELLOW}Installing gaming dependencies...${RC}"
    pacman $flags gnutls lib32-gnutls base-devel gtk3 lib32-gtk3 \
        python-google-auth python-protobuf libpulse lib32-libpulse \
        alsa-lib lib32-alsa-lib alsa-utils alsa-plugins lib32-alsa-plugins \
        giflib lib32-giflib libpng lib32-libpng libldap lib32-libldap \
        openal lib32-openal libxcomposite lib32-libxcomposite \
        libxinerama lib32-libxinerama libgcrypt lib32-libgcrypt \
        libgpg-error lib32-libgpg-error ncurses lib32-ncurses \
        mpg123 lib32-mpg123 libjpeg-turbo lib32-libjpeg-turbo \
        sqlite lib32-sqlite libva lib32-libva \
        gst-plugins-base-libs lib32-gst-plugins-base-libs \
        sdl2 lib32-sdl2 v4l-utils lib32-v4l-utils \
        vulkan-icd-loader lib32-vulkan-icd-loader \
        ocl-icd lib32-ocl-icd opencl-icd-loader lib32-opencl-icd-loader \
        libxslt lib32-libxslt cups samba lib32-mesa \
        vulkan-radeon lib32-vulkan-radeon gamescope mangohud lib32-mangohud \
        gamemode lib32-gamemode vulkan-intel lib32-vulkan-intel
    echo -e "${GREEN}Gaming dependencies installed${RC}"
}
# terminus font setup function
setup_terminus() {
    echo -e "${YELLOW}Setting up terminus font...${RC}"
    
    # Install terminus-font if not present
    if ! pacman -Qs terminus-font > /dev/null; then
        echo -e "${YELLOW}Installing terminus-font...${RC}"
        pacman -S --needed --noconfirm terminus-font
    else
        echo -e "${GREEN}terminus-font package is already installed${RC}"
    fi

    # Configure /etc/vconsole.conf
    echo -e "${YELLOW}Configuring /etc/vconsole.conf...${RC}"
    if [ -f /etc/vconsole.conf ]; then
        if grep -q "^FONT=" /etc/vconsole.conf; then
            sed -i 's/^FONT=.*/FONT=ter-v18b/' /etc/vconsole.conf
        else
            echo "FONT=ter-v18b" >> /etc/vconsole.conf
        fi
    else
        echo "FONT=ter-v18b" > /etc/vconsole.conf
    fi

    # Apply immediately if in TTY
    if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ]; then
        setfont ter-v18b
        echo -e "${GREEN}Font applied to current console${RC}"
    fi

    echo -e "${GREEN}Terminus font configuration completed${RC}"
}
# copy dotfiles function
copy_dotfiles() {
    echo -e "${YELLOW}Copying dotfiles...${RC}"
    
    if [ -d "$USER_HOME/hyprdots" ]; then
        # Create .config directory if it doesn't exist
        sudo -u $INSTALL_USER mkdir -p "$USER_HOME/.config"
        
        # Copy dotfiles
        sudo -u $INSTALL_USER cp -r "$USER_HOME/hyprdots/"* "$USER_HOME/.config/"
        echo -e "${GREEN}Dotfiles copied successfully${RC}"
    else
        echo -e "${RED}Warning: $USER_HOME/hyprdots directory not found, skipping...${RC}"
    fi
}
# setup SDDM function
setup_sddm() {
    echo -e "${YELLOW}Setting up SDDM...${RC}"
    systemctl enable sddm
    echo -e "${GREEN}SDDM setup completed${RC}"
}

# Main function 
main() {
    echo -e "${BLUE}========================================${RC}"
    echo -e "${BLUE}  Hyprland Setup Script for Arch Linux${RC}"
    echo -e "${BLUE}========================================${RC}"
    echo ""
    
    root_permission
    check_yay
    install_multilib
    configure_tlp
    install_dependencies_pacman
    install_dependencies_aur
    gaming_dependencies
    setup_terminus
    copy_dotfiles
    auto_login
    setup_sddm
    
    echo ""
    echo -e "${GREEN}========================================${RC}"
    echo -e "${GREEN}  Hyprland setup completed!${RC}"
    echo -e "${GREEN}========================================${RC}"
    echo -e "${YELLOW}The system will reboot in 5 seconds...${RC}"
    sleep 5
    reboot
}

main