#!/bin/bash
set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
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
  if ! command -v yay &>/dev/null; then
    echo -e "${YELLOW}yay could not be found, installing...${RC}"
    install_yay
  else
    echo -e "${GREEN}yay is already installed${RC}"
  fi
}

# enable multilib repository function
install_multilib() {
  if grep -q "^\[multilib\]" /etc/pacman.conf && ! grep -q "^#\[multilib\]" /etc/pacman.conf; then
    echo -e "${GREEN}Multilib repository is already enabled${RC}"
    return 0
  fi
  
  echo -e "${YELLOW}Enabling multilib repository...${RC}"
  sed -i '/\[multilib\]/,/Include = \/etc\/pacman.d\/mirrorlist/s/^#//' /etc/pacman.conf
  pacman -Syu --noconfirm
  echo -e "${GREEN}Multilib repository enabled${RC}"
}

# tlp configuration function
check_tlp() {
  if pacman -Qs tlp &>/dev/null; then
    echo -e "${GREEN}TLP is already installed${RC}"
    
    # Check if service is enabled
    if systemctl is-enabled tlp &>/dev/null; then
      echo -e "${GREEN}TLP service is already enabled${RC}"
    else
      echo -e "${YELLOW}Enabling TLP service...${RC}"
      systemctl enable tlp
      systemctl start tlp
      echo -e "${GREEN}TLP service enabled${RC}"
    fi
  else
    echo -e "${YELLOW}TLP not found, installing...${RC}"
    configure_tlp
  fi
}

configure_tlp() {
  echo -e "${YELLOW}Configuring TLP for power management...${RC}"
  pacman $flags tlp tlp-rdw
  systemctl enable tlp
  systemctl start tlp
  echo -e "${GREEN}TLP has been configured and started${RC}"
}

# install pacman dependencies function
install_dependencies_aur() {
  echo -e "${YELLOW}Checking AUR dependencies for Hyprland...${RC}"
  
  local aur_packages=()
  
  # Check waypaper
  if ! pacman -Qi waypaper &>/dev/null; then
    aur_packages+=("waypaper")
  else
    echo -e "${GREEN}waypaper is already installed${RC}"
  fi
  
  # Check google-chrome-bin
  if ! pacman -Qi google-chrome-bin &>/dev/null; then
    aur_packages+=("google-chrome-bin")
  else
    echo -e "${GREEN}google-chrome-bin is already installed${RC}"
  fi
  
  # Install only missing packages
  if [ ${#aur_packages[@]} -gt 0 ]; then
    echo -e "${YELLOW}Installing missing AUR packages: ${aur_packages[*]}${RC}"
    sudo -u $INSTALL_USER yay -S --noconfirm "${aur_packages[@]}"
    echo -e "${GREEN}AUR dependencies installed${RC}"
  else
    echo -e "${GREEN}All AUR dependencies are already installed${RC}"
  fi
}

install_dependencies_pacman() {
  echo -e "${YELLOW}Installing pacman dependencies${RC}"
  pacman $flags hyprland swww sddm alacritty thunar pavucontrol ttf-jetbrains-mono waybar discord xdg-desktop-portal \
    xdg-desktop-portal-hyprland hyprshot swaync
  echo -e "${GREEN}Pacman dependencies installed${RC}"
}

# install gaming dependencies function
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

configure_terminus_font() {
  # Check if already configured
  if [ -f /etc/vconsole.conf ] && grep -q "^FONT=ter-v18b" /etc/vconsole.conf; then
    echo -e "${GREEN}Terminus font is already configured${RC}"
    return 0
  fi
  
  echo -e "${YELLOW}Configuring Terminus font...${RC}"
  pacman $flags terminus-font
  
  # Configure /etc/vconsole.conf
  echo -e "${YELLOW}Configuring /etc/vconsole.conf...${RC}"
  if [ -f /etc/vconsole.conf ]; then
    if grep -q "^FONT=" /etc/vconsole.conf; then
      sed -i 's/^FONT=.*/FONT=ter-v18b/' /etc/vconsole.conf
    else
      echo "FONT=ter-v18b" >>/etc/vconsole.conf
    fi
  else
    echo "FONT=ter-v18b" >/etc/vconsole.conf
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

# Detect and remove old desktop environment
detect_de() {
    local DE=""
    
    # Method 1: XDG_CURRENT_DESKTOP (most reliable)
    if [ -n "$XDG_CURRENT_DESKTOP" ]; then
        DE="$XDG_CURRENT_DESKTOP"
    # Method 2: DESKTOP_SESSION
    elif [ -n "$DESKTOP_SESSION" ]; then
        DE="$DESKTOP_SESSION"
    # Method 3: XDG_SESSION_DESKTOP
    elif [ -n "$XDG_SESSION_DESKTOP" ]; then
        DE="$XDG_SESSION_DESKTOP"
    # Method 4: Check running processes
    elif pgrep -x "plasmashell" >/dev/null 2>&1 || pgrep -x "ksmserver" >/dev/null 2>&1; then
        DE="KDE"
    elif pgrep -x "gnome-shell" >/dev/null 2>&1; then
        DE="GNOME"
    elif pgrep -x "xfce4-session" >/dev/null 2>&1; then
        DE="XFCE"
    elif pgrep -x "mate-session" >/dev/null 2>&1; then
        DE="MATE"
    elif pgrep -x "cinnamon" >/dev/null 2>&1; then
        DE="CINNAMON"
    else
        DE="UNKNOWN"
    fi
    
    echo "$DE"
}

remove_old_de() {
    local desktop_env=$(detect_de)
    
    if [ -z "$desktop_env" ] || [ "$desktop_env" = "UNKNOWN" ]; then
        echo -e "${YELLOW}No Desktop Environment detected or already removed${RC}"
        return 0
    fi
    
    echo -e "${YELLOW}Desktop Environment detected: $desktop_env${RC}"
    echo -e "${BLUE}Removing only DE packages, keeping display managers intact${RC}"
    
    desktop_env=$(echo "$desktop_env" | tr '[:lower:]' '[:upper:]')
    
    case "$desktop_env" in
        *KDE*|*PLASMA*)
            echo -e "${YELLOW}Removing KDE Plasma (keeping SDDM)...${RC}"
            if pacman -Qi plasma-desktop >/dev/null 2>&1; then
                # Remove only DE, NOT sddm or other DMs
                pacman -Rns --noconfirm plasma-desktop plasma-workspace kde-applications kwalletmanager 2>/dev/null || true
                echo -e "${GREEN}KDE Plasma removed${RC}"
            else
                echo -e "${GREEN}KDE Plasma is not installed${RC}"
            fi
            ;;
        *GNOME*)
            echo -e "${YELLOW}Removing GNOME (keeping GDM)...${RC}"
            if pacman -Qi gnome-shell >/dev/null 2>&1; then
                # Remove gnome-shell and apps but keep GDM
                pacman -Rns --noconfirm gnome-shell gnome-control-center gnome-terminal nautilus 2>/dev/null || true
                echo -e "${GREEN}GNOME removed${RC}"
            else
                echo -e "${GREEN}GNOME is not installed${RC}"
            fi
            ;;  
        *XFCE*)
            echo -e "${YELLOW}Removing XFCE (keeping LightDM)...${RC}"
            if pacman -Qi xfce4-session >/dev/null 2>&1; then
                # Remove only XFCE, keep lightdm
                pacman -Rns --noconfirm xfce4-session xfce4-panel xfdesktop xfwm4 2>/dev/null || true
                echo -e "${GREEN}XFCE removed${RC}"
            else
                echo -e "${GREEN}XFCE is not installed${RC}"
            fi
            ;;
        *MATE*)
            echo -e "${YELLOW}Removing MATE (keeping LightDM)...${RC}"
            if pacman -Qi mate-session-manager >/dev/null 2>&1; then
                # Remove only MATE, keep lightdm
                pacman -Rns --noconfirm mate-session-manager mate-panel mate-desktop 2>/dev/null || true
                echo -e "${GREEN}MATE removed${RC}"
            else
                echo -e "${GREEN}MATE is not installed${RC}"
            fi
            ;;
        *CINNAMON*)
            echo -e "${YELLOW}Removing Cinnamon (keeping LightDM)...${RC}"
            if pacman -Qi cinnamon >/dev/null 2>&1; then
                # Remove only Cinnamon, keep lightdm
                pacman -Rns --noconfirm cinnamon 2>/dev/null || true
                echo -e "${GREEN}Cinnamon removed${RC}"
            else
                echo -e "${GREEN}Cinnamon is not installed${RC}"
            fi
            ;;
        *)
            echo -e "${YELLOW}Unrecognized Desktop Environment: $desktop_env${RC}"
            echo -e "${BLUE}Skipping DE removal for safety${RC}"
            ;;
    esac
}

# Main function
main() {
  echo -e "${BLUE}========================================${RC}"
  echo -e "${BLUE}  Hyprland Setup Script for Arch Linux${RC}"
  echo -e "${BLUE}========================================${RC}"
  echo ""

  root_permission
  remove_old_de
  check_yay
  install_multilib
  check_tlp
  install_dependencies_pacman
  install_dependencies_aur
  gaming_dependencies
  configure_terminus_font
  copy_dotfiles

  echo ""
  echo -e "${GREEN}========================================${RC}"
  echo -e "${GREEN}  Hyprland setup completed!${RC}"
  echo -e "${GREEN}========================================${RC}"
  echo -e "${YELLOW}The system will reboot in 5 seconds...${RC}"
  sleep 5
  reboot
}

main