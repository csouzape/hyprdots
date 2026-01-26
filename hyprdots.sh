#!/bin/bash
set -e 
# This script installs the necessary dependences for arch linux hyprland 
flags="-S -q --needed --noconfirm --noprogressbar"

#call for root permission
root_permision() {
    if [ "$EUID" -ne 0 ]; then
        echo "Please run as root"
        exit
    fi

}
# install yay
install_yay() {
    echo "Installing yay"
    pacman -S --noconfirm git base-devel
    git clone https://aur.archlinux.org/yay
    cd yay 
    makepkg -si --noconfirm
    cd .. 
    mv yay .config
    echo "yay installed"
}
check_yay() {
    if ! command -v yay &> /dev/null; then
        echo "yay could not be found, installing..."
        install_yay
    else
        echo "yay is already installed."
    fi
}
install_multilib() {
    echo "Enabling multilib repository..."
    sudo sed -i '/\[multilib\]/,/Include = \/etc\/pacman.d\/mirrorlist/s/^#//' /etc/pacman.conf
    sudo pacman -Syu
    echo "Multilib repository enabled."
}
# tlp configuration function
configure_tlp() {
    echo "Configuring TLP for power management..."
    sudo pacman $flags tlp tlp-rdw
    sudo systemctl enable tlp
    sudo systemctl start tlp
    echo "TLP has been configured and started."
}

install_depencences_pacman() {
    echo "Installing dependencies for Hyprland..."
    sudo pacman $flags hyprland waybar alacritty rofi thunar nerd-fonts ttf-jetbrains-mono pavucontrol swww sddm fastfetch
}

install_depences_aur() {
    echo "Installing AUR dependencies for Hyprland..."
    yay -S --noconfirm yay -S google-chrome waypaper
}
auto_login() {
    echo "Setting up auto-login for user carlos..."
    sudo mkdir -p /etc/sddm.conf.d
    echo "[Autologin]" | sudo tee /etc/sddm.conf.d/autologin.conf
    echo "User=carlos" | sudo tee -a /etc/sddm.conf.d/autologin.conf
    echo "Session=hyprland" | sudo tee -a /etc/sddm.conf.d/autologin.conf
    echo "Auto-login configured for user carlos."
}
gaming_dependences() {
    echo "Installing gaming dependencies..."
    sudo pacman $flags gnutls lib32-gnutls base-devel gtk3 lib32-gtk3 python-google-auth python-protobuf \
        libpulse lib32-libpulse alsa-lib lib32-alsa-lib alsa-utils alsa-plugins lib32-alsa-plugins \
        giflib lib32-giflib libpng lib32-libpng libldap lib32-libldap openal lib32-openal \
        libxcomposite lib32-libxcomposite libxinerama lib32-libxinerama libgcrypt lib32-libgcrypt \
        libgpg-error lib32-libgpg-error ncurses lib32-ncurses mpg123 lib32-mpg123 \
        libjpeg-turbo lib32-libjpeg-turbo sqlite lib32-sqlite libva lib32-libva \
        gst-plugins-base-libs lib32-gst-plugins-base-libs sdl2 lib32-sdl2 v4l-utils lib32-v4l-utils \
        vulkan-icd-loader lib32-vulkan-icd-loader ocl-icd lib32-ocl-icd opencl-icd-loader lib32-opencl-icd-loader \
        libxslt lib32-libxslt cups samba lib32-mesa vulkan-radeon lib32-vulkan-radeon \
        gamescope mangohud lib32-mangohud gamemode lib32-gamemode
}

setup_terminus() {
    # 1. Install terminus-font if not present
    if ! pacman -Qs terminus-font > /dev/null; then
        printf "%b\n" "${YELLOW}Instalando terminus-font...${RC}"
        sudo pacman -S --needed --noconfirm terminus-font
    else
        printf "%b\n" "${GREEN}Pacote terminus-font já está presente.${RC}"
    fi

    # 2. system config
    printf "%b\n" "${YELLOW}Configurando /etc/vconsole.conf...${RC}"
    if [ -f /etc/vconsole.conf ]; then
        # Se a linha FONT já existir, substitui. Se não, adiciona ao final.
        grep -q "^FONT=" /etc/vconsole.conf && \
        sudo sed -i 's/^FONT=.*/FONT=ter-v18b/' /etc/vconsole.conf || \
        echo "FONT=ter-v18b" | sudo tee -a /etc/vconsole.conf
    else
        echo "FONT=ter-v18b" | sudo tee /etc/vconsole.conf
    fi

    # 3. Aplicação Imediata (Somente se estiver em TTY)
    if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ]; then
        sudo setfont ter-v18b
        printf "%b\n" "${GREEN}Fonte aplicada ao console atual.${RC}"
    fi

    printf "%b\n" "${GREEN}Configuração da fonte concluída!${RC}"
}

copy_dotfiles() {
    echo "Copying dotfiles..."
    cp -r "/home/carlos/hyprdots/" /home/carlos/.config/
    echo "Dotfiles copied."
}

setup_sddm() {
    echo "Setting up SDDM..."
    sudo systemctl enable sddm
    echo "SDDM setup completed."
}
# Main function 
main() {
    root_permision
    check_yay
    install_multilib
    configure_tlp
    install_depencences_pacman
    install_depences_aur
    gaming_dependences
    setup_terminus
    copy_dotfiles
    auto_login
    setup_sddm
    echo "Hyprland setup completed!"
}
main
reboot

