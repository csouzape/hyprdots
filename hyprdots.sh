#!/bin/bash 
# This script installs the necessary dependences for arch linux hyprland 
echo "Root previlages are required to run this script"
if [ "$EUID" -ne 0 ]
    then echo "Please run as root"
    exit
fi
echo "Updating system..."
pacman -Syu --noconfirm
# yay install 
if ! command -v yay &> /dev/null
then
    echo "Yay could not be found, installing yay..."
    pacman -S --noconfirm git base-devel
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ..
    mv yay .config/
fi 
echo "Installing depences..."
sudo pacman -S --noconfirm hyprland waybar alacritty hyprshot swww nerd-fonts rofi thunar 
echo "yay depencences.."
yay -S --noconfirm waypaper google-chrome 