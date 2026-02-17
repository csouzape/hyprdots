#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RC='\033[0m'

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

remove_kde() {
	echo -e "${YELLOW}Removing KDE Plasma...${RC}"
	dnf group remove -y "KDE Plasma Workspaces"
	dnf remove -y --setopt=protected_packages= \
		plasma-desktop plasma-workspace* plasma-* \
		kde-* kf5-* kf6-* \
		konsole dolphin ark gwenview
	echo -e "${GREEN}KDE Plasma removed${RC}"
}

sddm() {
	if ! rpm -q sddm &>/dev/null; then
		echo -e "${YELLOW}SDDM not found. Installing...${RC}"
		dnf install -y sddm || { echo -e "${RED}ERROR: Failed to install SDDM${RC}"; return 1; }
	fi
	echo -e "${BLUE}Configuring SDDM...${RC}"
	systemctl enable sddm.service --force
	systemctl set-default graphical.target
	echo -e "${GREEN}SDDM configured as default display manager${RC}"
}

auto_login() {
	echo -e "${YELLOW}Configuring auto-login for $INSTALL_USER...${RC}"
	local SDDM_CONF="/etc/sddm.conf"

	if grep -q "AutoLoginUser=$INSTALL_USER" "$SDDM_CONF" 2>/dev/null; then
		echo -e "${GREEN}Auto-login already configured for $INSTALL_USER${RC}"
		return 0
	fi

	cat > "$SDDM_CONF" << SDDM
[Autologin]
User=$INSTALL_USER
Session=hyprland
SDDM

	echo -e "${GREEN}Auto-login configured for $INSTALL_USER${RC}"
}

enable_hypr_repo() {
	echo -e "${YELLOW}Enabling Hyprland repository...${RC}"
	dnf install ${DNF_FLAGS} dnf-plugins-core
	HYPR_COPR=${HYPR_COPR:-solopasha/hyprland}
	if dnf copr list 2>/dev/null | grep -q "$HYPR_COPR"; then
		echo -e "${GREEN}Repository already enabled${RC}"
	else
		dnf copr enable -y ${HYPR_COPR}
		echo -e "${GREEN}Repository enabled${RC}"
	fi
}

install_packages() {
	echo -e "${YELLOW}Installing packages via dnf...${RC}"
	local PACKAGES=(
		hyprland sddm alacritty thunar pavucontrol
		jetbrains-mono-fonts waybar xdg-desktop-portal-gtk
		hyprshot swaync rofi waypaper swww playerctl nwg-look
	)
	dnf install ${DNF_FLAGS} "${PACKAGES[@]}"
	if ! command -v Hyprland &>/dev/null; then
		echo -e "${RED}ERROR: Hyprland installation failed${RC}"
		exit 1
	fi
	echo -e "${GREEN}All packages installed${RC}"
}

flatpak_install() {
	echo -e "${YELLOW}Installing Flatpak packages...${RC}"
	local FLATPAK_PACKAGES=(
		com.spotify.Client
		com.visualstudio.code
		com.github.tchx84.Flatseal
	)
	for pkg in "${FLATPAK_PACKAGES[@]}"; do
		if flatpak list --app | grep -q "$pkg"; then
			echo -e "${GREEN}$pkg already installed${RC}"
		else
			flatpak install -y flathub "$pkg" || echo -e "${RED}ERROR: Failed to install $pkg${RC}"
		fi
	done
	echo -e "${GREEN}Flatpak packages installation completed${RC}"
}

configure_tlp() {
	echo -e "${YELLOW}Configuring TLP...${RC}"
	if systemctl is-enabled tuned &>/dev/null; then
		systemctl disable --now tuned.service || true
		dnf remove ${DNF_FLAGS} tuned || true
	fi
	dnf install ${DNF_FLAGS} tlp tlp-rdw
	systemctl enable --now tlp
	echo -e "${GREEN}TLP configured${RC}"
}

copy_dotfiles() {
	echo -e "${YELLOW}Copying dotfiles...${RC}"
	[ -z "${INSTALL_USER:-}" ] && { echo "INSTALL_USER not set"; return 1; }
	local USER_HOME CONFIG_DIR SCRIPT_DIR DOTFILES_SOURCE
	USER_HOME=$(eval echo "~$INSTALL_USER")
	CONFIG_DIR="$USER_HOME/.config"
	SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
	DOTFILES_SOURCE="$SCRIPT_DIR"

	if [ ! -d "$DOTFILES_SOURCE" ]; then
		for alt in "$USER_HOME/hyprdots/distro/fedora" "$USER_HOME/hyprdots/distros/fedora" "$USER_HOME/hyprdots/fedora"; do
			[ -d "$alt" ] && { DOTFILES_SOURCE="$alt"; break; }
		done
		[ ! -d "$DOTFILES_SOURCE" ] && { echo -e "${RED}Error: No valid dotfiles directory found${RC}"; return 1; }
	fi

	echo -e "${GREEN}Using dotfiles at: $DOTFILES_SOURCE${RC}"
	runuser -u "$INSTALL_USER" -- mkdir -p "$CONFIG_DIR" || return 1

	if command -v rsync &>/dev/null; then
		runuser -u "$INSTALL_USER" -- rsync -a --delete "$DOTFILES_SOURCE/." "$CONFIG_DIR/" || return 1
	else
		runuser -u "$INSTALL_USER" -- cp -a "$DOTFILES_SOURCE/." "$CONFIG_DIR/" || return 1
	fi

	for file in "hypr/hyprland.conf" "waybar/config"; do
		[ ! -f "$CONFIG_DIR/$file" ] && { echo -e "${RED}Missing essential file: $file${RC}"; return 1; }
	done

	echo -e "${GREEN}Dotfiles copied and verified${RC}"
}

wallpapers_config() {
	local TARGET_DIR="$USER_HOME/Imagens/wallpapers"
	[ -z "${INSTALL_USER:-}" ] && { echo "INSTALL_USER not set"; return 1; }
	runuser -u "$INSTALL_USER" -- mkdir -p "$TARGET_DIR" || return 1

	if [ -d "$TARGET_DIR/.git" ]; then
		echo -e "${YELLOW}Updating wallpapers...${RC}"
		runuser -u "$INSTALL_USER" -- git -C "$TARGET_DIR" pull --ff-only || { echo -e "${RED}Failed to update wallpapers${RC}"; return 1; }
	else
		echo -e "${YELLOW}Cloning wallpapers...${RC}"
		runuser -u "$INSTALL_USER" -- git clone --depth=1 https://github.com/csouzape/wallpapers "$TARGET_DIR" || { echo -e "${RED}Failed to clone wallpapers${RC}"; return 1; }
	fi
	echo -e "${GREEN}Wallpapers ready${RC}"
}

install_materia_theme() {
	echo -e "${YELLOW}Installing Materia Theme...${RC}"
	local TMP_DIR
	TMP_DIR="$(mktemp -d /tmp/materia-theme.XXXXXX)"
	trap "rm -rf $TMP_DIR" RETURN

	for dep in git meson ninja sassc; do
		command -v "$dep" &>/dev/null || { echo -e "${RED}Missing dependency: $dep${RC}"; return 1; }
	done

	git clone --depth=1 https://github.com/nana-4/materia-theme.git "$TMP_DIR" || return 1
	meson setup --prefix=/usr "$TMP_DIR/build" "$TMP_DIR" || return 1
	ninja -C "$TMP_DIR/build" || return 1
	ninja -C "$TMP_DIR/build" install || return 1

	echo -e "${GREEN}Materia Theme installed${RC}"
}


main() {
	echo -e "${BLUE}========================================${RC}"
	echo -e "${BLUE}  Hyprland Setup Script for Fedora${RC}"
	echo -e "${BLUE}  User: $INSTALL_USER | Home: $USER_HOME${RC}"
	echo -e "${BLUE}========================================${RC}"

	root_permission

	echo -e "${BLUE}========================================${RC}"
	echo "1) Install Hyprland"
	echo "2) Remove KDE Plasma only"
	echo "3) Cancel"
	echo -e "${BLUE}========================================${RC}"
	read -rp "Select an option [1-3]: " MENU_OPTION

	case "$MENU_OPTION" in
		1)
			echo -e "${GREEN}Starting Hyprland installation...${RC}"
			enable_hypr_repo
			install_packages
			configure_tlp
			install_materia_theme
			wallpapers_config
			flatpak_install
			copy_dotfiles || echo -e "${YELLOW}Some config files may be missing — verify manually${RC}"
			echo -e "${GREEN}Setup completed! Reboot to start using Hyprland.${RC}"
			;;
		2)
			remove_kde
			sddm
			auto_login
			echo -e "${GREEN}KDE removal finished.${RC}"
			;;
		3)
			echo -e "${RED}Cancelled.${RC}"
			exit 0
			;;
		*)
			echo -e "${RED}Invalid option.${RC}"
			exit 1
			;;
	esac
}

main "$@"