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
	echo -e "${YELLOW}Removing KDE Plasma (keeping SDDM)...${RC}"

	if dnf groupinfo "KDE Plasma Workspaces" &>/dev/null; then
		sudo dnf groupremove -y ${DNF_FLAGS} "KDE Plasma Workspaces"
		sudo dnf remove -y \
			--setopt=protected_packages= \
			plasma-desktop \
			plasma-workspace* \
			plasma-* \
			kde-* \
			kf5-* \
			kf6-* \
			konsole dolphin ark gwenview

		echo -e "${GREEN}KDE Plasma removed (SDDM preserved)${RC}"
	else
		echo -e "${YELLOW}KDE Plasma not found — skipping${RC}"
	fi
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
		hyprland
		sddm
		alacritty
		thunar
		pavucontrol
		jetbrains-mono-fonts
		waybar
		xdg-desktop-portal-gtk
		hyprshot
		swaync
		rofi
		waypaper
		swww
	)
	
	dnf install ${DNF_FLAGS} "${PACKAGES[@]}"
	
	if ! command -v Hyprland &>/dev/null; then
		echo -e "${RED}ERROR: Hyprland installation failed${RC}"
		exit 1
	fi
	
	echo -e "${GREEN}All packages installed${RC}"
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

verify_dotfiles_copy() {
	local SOURCE="$1"
	local DEST="$2"
	
	echo -e "${YELLOW}Verifying copied files...${RC}"
	
	local CRITICAL_CONFIGS=(
		"hypr/hyprland.conf"
		"waybar/config"
		"rofi/config.rasi"
	)
	
	local MISSING_CRITICAL=0
	
	# Verificar arquivos críticos
	for config in "${CRITICAL_CONFIGS[@]}"; do
		if [ -f "$SOURCE/$config" ]; then
			if [ -f "$DEST/$config" ]; then
				echo -e "${GREEN}  ✓ $config${RC}"
			else
				((MISSING_CRITICAL++))
				echo -e "${RED}  ✗ $config (MISSING)${RC}"
			fi
		fi
	done
	
	# Verificar diretórios principais
	echo -e "${YELLOW}Checking main directories...${RC}"
	for dir in "$SOURCE"/*; do
		if [ -d "$dir" ]; then
			local dirname=$(basename "$dir")
			if [ -d "$DEST/$dirname" ]; then
				local src_files=$(find "$dir" -type f 2>/dev/null | wc -l)
				local dst_files=$(find "$DEST/$dirname" -type f 2>/dev/null | wc -l)
				
				if [ "$src_files" -eq "$dst_files" ]; then
					echo -e "${GREEN}  ✓ $dirname/ ($dst_files files)${RC}"
				else
					echo -e "${YELLOW}  ⚠ $dirname/ ($dst_files/$src_files files)${RC}"
				fi
			else
				echo -e "${RED}  ✗ $dirname/ (directory missing)${RC}"
				((MISSING_CRITICAL++))
			fi
		fi
	done
	
	# Resultado final
	echo -e "${BLUE}========================================${RC}"
	if [ $MISSING_CRITICAL -gt 0 ]; then
		echo -e "${RED}WARNING: $MISSING_CRITICAL critical issues found!${RC}"
		return 1
	else
		echo -e "${GREEN}All critical configurations verified!${RC}"
		return 0
	fi
}

auto_fix_dotfiles() {
	echo -e "${YELLOW}Attempting intelligent auto-fix...${RC}"
	
	local DOTFILES_SOURCE="$1"
	local CONFIG_DIR="$2"
	
	# Método 2: Tentar com rsync (se disponível)
	if command -v rsync &>/dev/null; then
		echo -e "${BLUE}Method 2: Using rsync for robust copy...${RC}"
		dnf install ${DNF_FLAGS} rsync 2>/dev/null || true
		if command -v rsync &>/dev/null; then
			rsync -av --chown=$INSTALL_USER:$INSTALL_USER "$DOTFILES_SOURCE/" "$CONFIG_DIR/"
			chown -R $INSTALL_USER:$INSTALL_USER "$CONFIG_DIR"
			
			if verify_dotfiles_copy "$DOTFILES_SOURCE" "$CONFIG_DIR"; then
				return 0
			fi
		fi
	fi
	
	# Método 3: Cópia arquivo por arquivo com find
	echo -e "${BLUE}Method 3: Using find-based copy...${RC}"
	cd "$DOTFILES_SOURCE" || return 1
	find . -type f | while read -r file; do
		local target_dir="$CONFIG_DIR/$(dirname "$file")"
		sudo -u $INSTALL_USER mkdir -p "$target_dir"
		sudo -u $INSTALL_USER cp -f "$file" "$target_dir/" 2>/dev/null || true
	done
	cd - > /dev/null
	
	chown -R $INSTALL_USER:$INSTALL_USER "$CONFIG_DIR"
	
	# Verificar novamente
	if verify_dotfiles_copy "$DOTFILES_SOURCE" "$CONFIG_DIR"; then
		return 0
	else
		return 1
	fi
}

copy_dotfiles() {
	echo -e "${YELLOW}Copying dotfiles...${RC}"
	
	local DOTFILES_SOURCE="$USER_HOME/hyprdots/distro/fedora"
	local CONFIG_DIR="$USER_HOME/.config"
	
	# Procurar pelo diretório de dotfiles
	if [ ! -d "$DOTFILES_SOURCE" ]; then
		echo -e "${YELLOW}Trying alternative paths...${RC}"
		
		local ALTERNATIVE_PATHS=(
			"$USER_HOME/hyprdots/distros/fedora"
			"$USER_HOME/hyprdots/fedora"
			"/home/$INSTALL_USER/hyprdots/distro/fedora"
		)
		
		for alt_path in "${ALTERNATIVE_PATHS[@]}"; do
			if [ -d "$alt_path" ]; then
				DOTFILES_SOURCE="$alt_path"
				echo -e "${GREEN}Found at: $DOTFILES_SOURCE${RC}"
				break
			fi
		done
		
		if [ ! -d "$DOTFILES_SOURCE" ]; then
			echo -e "${RED}Error: No valid dotfiles directory found${RC}"
			echo -e "${YELLOW}Please ensure hyprdots repository is cloned to $USER_HOME${RC}"
			return 1
		fi
	fi
	
	echo -e "${GREEN}Found dotfiles at: $DOTFILES_SOURCE${RC}"
	
	# Criar .config se não existir
	sudo -u $INSTALL_USER mkdir -p "$CONFIG_DIR"
	
	# Método 1: Cópia padrão recursiva
	echo -e "${BLUE}Method 1: Standard recursive copy...${RC}"
	if sudo -u $INSTALL_USER cp -rf "$DOTFILES_SOURCE/"* "$CONFIG_DIR/" 2>/dev/null; then
		chown -R $INSTALL_USER:$INSTALL_USER "$CONFIG_DIR"
		echo -e "${GREEN}Standard copy completed${RC}"
		
		# Verificar se funcionou
		if verify_dotfiles_copy "$DOTFILES_SOURCE" "$CONFIG_DIR"; then
			echo -e "${GREEN}Dotfiles successfully copied and verified!${RC}"
			return 0
		else
			echo -e "${YELLOW}Standard copy incomplete, trying alternative methods...${RC}"
			auto_fix_dotfiles "$DOTFILES_SOURCE" "$CONFIG_DIR"
			return $?
		fi
	else
		echo -e "${YELLOW}Standard copy failed, trying alternative methods...${RC}"
		auto_fix_dotfiles "$DOTFILES_SOURCE" "$CONFIG_DIR"
		return $?
	fi
}

auto_login() {
	echo -e "${YELLOW}Configuring SDDM autologin...${RC}"
	
	mkdir -p /etc/sddm.conf.d
	cat > /etc/sddm.conf.d/autologin.conf <<EOF
[Autologin]
User=$INSTALL_USER
Session=hyprland
EOF
	echo -e "${GREEN}Autologin enabled${RC}"
}

setup_sddm() {
	echo -e "${YELLOW}Configuring SDDM...${RC}"
	
	dnf install ${DNF_FLAGS} sddm
	
	# Desabilitar outros display managers
	for dm in gdm lightdm lxdm; do
		if systemctl is-enabled $dm &>/dev/null; then
			systemctl disable $dm || true
		fi
	done
	
	systemctl enable sddm
	echo -e "${GREEN}SDDM enabled${RC}"
}

installFont() {
    FONT_NAME="MesloLGS Nerd Font Mono"
    
    # Verifica se a fonte já está instalada
    if fc-list :family | grep -iq "$FONT_NAME"; then
        echo "Fonte '$FONT_NAME' já instalada."
        return
    fi
    
    echo "Instalando fonte '$FONT_NAME'..."
	
    FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip"
    FONT_DIR="$HOME/.local/share/fonts/$FONT_NAME"
    TEMP_DIR=$(mktemp -d)
    
    curl -sSLo "$TEMP_DIR/font.zip" "$FONT_URL"
    unzip -q "$TEMP_DIR/font.zip" -d "$TEMP_DIR"
    mkdir -p "$FONT_DIR"
    mv "$TEMP_DIR"/*.ttf "$FONT_DIR"
    fc-cache -f
    rm -rf "$TEMP_DIR"
    
    echo "Fonte '$FONT_NAME' instalada com sucesso."
}

main() {
	echo -e "${BLUE}========================================${RC}"
	echo -e "${BLUE}  Hyprland Setup Script for Fedora${RC}"
	echo -e "${BLUE}========================================${RC}"
	echo -e "${BLUE}  User: $INSTALL_USER${RC}"
	echo -e "${BLUE}  Home: $USER_HOME${RC}"
	echo -e "${BLUE}========================================${RC}"
	echo

	root_permission
	remove_kde_keep_sddm
	enable_hypr_repo
	install_packages
	configure_tlp
	installFont
	
	# Copiar dotfiles com auto-fix se necessário
	if ! copy_dotfiles; then
		echo -e "${YELLOW}Some configuration files may be missing${RC}"
		echo -e "${YELLOW}Please verify manually after installation${RC}"
	fi
	
	auto_login
	setup_sddm

	echo
	echo -e "${GREEN}========================================${RC}"
	echo -e "${GREEN}  Hyprland setup completed!${RC}"
	echo -e "${GREEN}========================================${RC}"
	echo -e "${YELLOW}Reboot to start using Hyprland${RC}"
	echo -e "${GREEN}========================================${RC}"
}

main "$@"