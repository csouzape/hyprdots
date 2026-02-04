#!/bin/bash
set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RC='\033[0m'

# who invoked sudo (or fallback to current user)
INSTALL_USER=${SUDO_USER:-$USER}
USER_HOME=$(eval echo ~$INSTALL_USER)

DNF_FLAGS="-y"

root_permission() {
	if [ "$EUID" -ne 0 ]; then
		echo -e "${RED}Please run as root or with sudo${RC}"
		exit 1
	fi
	echo -e "${GREEN}Running with root privileges${RC}"
}

remove_kde_keep_sddm() {
	echo -e "${YELLOW}Removing KDE packages (attempting to keep SDDM)...${RC}"
	# try to remove KDE group if present
	if dnf groupinfo "KDE Plasma Workspaces" &>/dev/null; then
		dnf groupremove ${DNF_FLAGS} "KDE Plasma Workspaces" || true
	fi

	# best-effort remove of common KDE/plasma packages but avoid touching sddm
	dnf remove ${DNF_FLAGS} "plasma-*" "kde-*" "kde\:*" || true
	echo -e "${GREEN}KDE removal step finished${RC}"
}

enable_hypr_repo() {
	echo -e "${YELLOW}Enabling Hyprland repository...${RC}"
	dnf install ${DNF_FLAGS} dnf-plugins-core || true
	HYPR_COPR=${HYPR_COPR:-solopasha/hyprland}
	if dnf copr list 2>/dev/null | grep -q "$HYPR_COPR"; then
		echo -e "${GREEN}Hyprland repository ($HYPR_COPR) already enabled${RC}"
	else
		dnf copr enable -y ${HYPR_COPR} || echo -e "${YELLOW}Warning: couldn't enable ${HYPR_COPR}${RC}"
		echo -e "${GREEN}Hyprland repository enabled${RC}"
	fi
}


install_packages() {
	echo -e "${YELLOW}Installing packages via dnf...${RC}"
	dnf install ${DNF_FLAGS} hyprland sddm alacritty thunar pavucontrol jetbrains-mono-fonts waybar xdg-desktop-portal-gtk hyprshot || true
	echo -e "${GREEN}Package installation attempted${RC}"
}

configure_tlp() {
	echo -e "${YELLOW}Configuring TLP (power management)...${RC}"

	# Remove tuned if present to avoid conflicts with tlp
	if dnf list installed tuned &>/dev/null; then
		echo -e "${YELLOW}Removing tuned to avoid conflicts...${RC}"
		systemctl disable --now tuned.service || true
		dnf remove ${DNF_FLAGS} tuned || true
	fi

	dnf install ${DNF_FLAGS} tlp tlp-rdw || true
	systemctl enable --now tlp || true
	echo -e "${GREEN}TLP configured${RC}"
}

copy_dotfiles() {
	echo -e "${YELLOW}Copying dotfiles (if $USER_HOME/hyprdots exists)...${RC}"
	if [ -d "$USER_HOME/hyprdots" ]; then
		sudo -u $INSTALL_USER mkdir -p "$USER_HOME/.config"
		sudo -u $INSTALL_USER cp -r "$USER_HOME/hyprdots/"* "$USER_HOME/.config/" || true
		chown -R $INSTALL_USER:$INSTALL_USER "$USER_HOME/.config" || true
		echo -e "${GREEN}Dotfiles copied to $USER_HOME/.config${RC}"
	else
		echo -e "${YELLOW}No $USER_HOME/hyprdots directory found — skipping copy${RC}"
	fi
}

auto_login() {
	echo -e "${YELLOW}Configuring SDDM autologin for $INSTALL_USER...${RC}"
	mkdir -p /etc/sddm.conf.d
	cat > /etc/sddm.conf.d/autologin.conf <<EOF
[Autologin]
User=$INSTALL_USER
Session=hyprland
EOF
	echo -e "${GREEN}Autologin configured${RC}"
}

setup_sddm() {
	echo -e "${YELLOW}Enabling SDDM...${RC}"
	dnf install ${DNF_FLAGS} sddm || true
	systemctl enable sddm || true
	echo -e "${GREEN}SDDM enabled${RC}"
}

main() {
	echo -e "${BLUE}========================================${RC}"
	echo -e "${BLUE}  Hyprland Setup Script for Fedora${RC}"
	echo -e "${BLUE}========================================${RC}"

	root_permission
	remove_kde_keep_sddm
	enable_hypr_repo
	install_packages
	configure_tlp
	copy_dotfiles
	auto_login
	setup_sddm

	echo -e "${GREEN}========================================${RC}"
	echo -e "${GREEN}  Hyprland setup (Fedora) finished${RC}"
	echo -e "${YELLOW}Please review the script and run it on your Fedora machine. Reboot when ready.${RC}"
}

main