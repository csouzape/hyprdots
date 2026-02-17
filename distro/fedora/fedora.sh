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
    sudo dnf group remove -y "KDE Plasma Workspaces"
    sudo dnf remove -y \
        --setopt=protected_packages= \
        plasma-desktop \
        plasma-workspace* \
        plasma-* \
        kde-* \
        kf5-* \
        kf6-* \
        konsole dolphin ark gwenview

    echo -e "${GREEN}KDE Plasma removed${RC}"
}


sddm() {
    if ! rpm -q sddm &>/dev/null; then
        echo -e "${YELLOW}SDDM not found. Installing...${RC}"
        sudo dnf install -y sddm || {
            echo -e "${RED}ERROR: Failed to install SDDM${RC}"
            return 1
        }
    fi

    echo -e "${BLUE}Configuring SDDM...${RC}"
    sudo systemctl enable sddm.service --force
    sudo systemctl set-default graphical.target

    echo -e "${GREEN}SDDM configured as default display manager${RC}"
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
		playerctl
		breeze-gtk
		nwg-look
	)
	
	dnf install ${DNF_FLAGS} "${PACKAGES[@]}"
	
	if ! command -v Hyprland &>/dev/null; then
		echo -e "${RED}ERROR: Hyprland installation failed${RC}"
		exit 1
	fi
	
	echo -e "${GREEN}All packages installed${RC}"
}

flatpak_install(){
	echo -e "${YELLOW}Installing Flatpak packages...${RC}"
	
	local FLATPAK_PACKAGES=(
		com.spotify.Client
		com.visualstudio.code
		com.github.tchx84.Flatseal

	)
	
	for pkg in "${FLATPAK_PACKAGES[@]}"; do
		if flatpak list --app | grep -q "$pkg"; then
			echo -e "${GREEN}Flatpak package $pkg already installed${RC}"
		else
			flatpak install -y flathub "$pkg" || {
				echo -e "${RED}ERROR: Failed to install $pkg via Flatpak${RC}"
			}
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

    # Validação básica
    [ -z "${INSTALL_USER:-}" ] && { echo "INSTALL_USER not set"; return 1; }

    local USER_HOME
    USER_HOME=$(eval echo "~$INSTALL_USER")

    local DOTFILES_SOURCE="$USER_HOME/hyprdots/distro/fedora"
    local CONFIG_DIR="$USER_HOME/.config"

    if [ ! -d "$DOTFILES_SOURCE" ]; then
        echo -e "${YELLOW}Trying alternative paths...${RC}"

        local ALTERNATIVE_PATHS=(
            "$USER_HOME/hyprdots/distros/fedora"
            "$USER_HOME/hyprdots/fedora"
        )

        for alt_path in "${ALTERNATIVE_PATHS[@]}"; do
            if [ -d "$alt_path" ]; then
                DOTFILES_SOURCE="$alt_path"
                echo -e "${GREEN}Found at: $DOTFILES_SOURCE${RC}"
                break
            fi
        done

        [ ! -d "$DOTFILES_SOURCE" ] && {
            echo -e "${RED}Error: No valid dotfiles directory found${RC}"
            return 1
        }
    fi

    echo -e "${GREEN}Using dotfiles at: $DOTFILES_SOURCE${RC}"

    runuser -u "$INSTALL_USER" -- mkdir -p "$CONFIG_DIR" || return 1

    echo -e "${BLUE}Copying files...${RC}"

    if command -v rsync &>/dev/null; then
        runuser -u "$INSTALL_USER" -- rsync -a --delete \
            "$DOTFILES_SOURCE/." "$CONFIG_DIR/" || return 1
    else
        runuser -u "$INSTALL_USER" -- cp -a \
            "$DOTFILES_SOURCE/." "$CONFIG_DIR/" || return 1
    fi

    echo -e "${GREEN}Dotfiles copy completed${RC}"

    if verify_dotfiles_copy "$DOTFILES_SOURCE" "$CONFIG_DIR"; then
        echo -e "${GREEN}Dotfiles successfully copied and verified!${RC}"
        return 0
    else
        echo -e "${YELLOW}Verification failed${RC}"
        return 1
    fi
}


verify_dotfiles_copy() {
    local SOURCE="$1"
    local DEST="$2"
    
    local ESSENTIAL_FILES=(
        "hypr/hyprland.conf"
        "waybar/config"
    )
    for file in "${ESSENTIAL_FILES[@]}"; do
        if [ ! -f "$DEST/$file" ]; then
            echo -e "${RED}Missing essential file: $file${RC}"
            return 1
        fi
    done
    return 0
}

wallpapers_config() {
    local TARGET_DIR="$USER_HOME/Imagens/wallpapers"

    # Garantir que variáveis existem
    [ -z "${INSTALL_USER:-}" ] && { echo "INSTALL_USER not set"; return 1; }
    [ -z "${USER_HOME:-}" ] && { echo "USER_HOME not set"; return 1; }

    # Criar diretório completo
    runuser -u "$INSTALL_USER" -- mkdir -p "$TARGET_DIR" || return 1

    if [ -d "$TARGET_DIR/.git" ]; then
        echo -e "${YELLOW}Updating wallpapers...${RC}"
        if runuser -u "$INSTALL_USER" -- git -C "$TARGET_DIR" pull --ff-only; then
            echo -e "${GREEN}Wallpapers updated${RC}"
        else
            echo -e "${RED}Failed to update wallpapers${RC}"
            return 1
        fi
    else
        echo -e "${YELLOW}Cloning wallpapers...${RC}"
        if runuser -u "$INSTALL_USER" -- git clone --depth=1 \
            https://github.com/csouzape/wallpapers \
            "$TARGET_DIR"; then
            echo -e "${GREEN}Wallpapers cloned${RC}"
        else
            echo -e "${RED}Failed to clone wallpapers${RC}"
            return 1
        fi
    fi
}

install_mybash() {
    set -e

    local gitpath="$HOME/.local/share/mybash"
    local FONT_NAME="MesloLGS Nerd Font Mono"
    local FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip"
    local FONT_DIR="$HOME/.local/share/fonts"
    local TEMP_DIR
    local STARSHIP_CONFIG="$HOME/.config/starship.toml"

    command_exists() { command -v "$1" >/dev/null 2>&1; }

    # Dependências
    if ! command_exists git || ! command_exists tar || ! command_exists unzip || ! command_exists fc-list; then
        echo "Installing dependencies..."
        if command_exists dnf; then
            sudo dnf install -y git tar unzip fontconfig
        elif command_exists pacman; then
            sudo pacman -S --needed --noconfirm git tar unzip fontconfig
        fi
    fi

    # Clonar mybash
    [ -d "$gitpath" ] && rm -rf "$gitpath"
    mkdir -p "$(dirname "$gitpath")"
    git clone https://github.com/ChrisTitusTech/mybash.git "$gitpath"

    # Fonte
    if ! fc-list :family | grep -iq "$FONT_NAME"; then
        echo "Installing font $FONT_NAME..."
        TEMP_DIR=$(mktemp -d)
        curl -sSLo "$TEMP_DIR/${FONT_NAME}.zip" "$FONT_URL"
        unzip "$TEMP_DIR/${FONT_NAME}.zip" -d "$TEMP_DIR"
        mkdir -p "$FONT_DIR/$FONT_NAME"
        mv "$TEMP_DIR"/*.ttf "$FONT_DIR/$FONT_NAME"
        fc-cache -fv
        rm -rf "$TEMP_DIR"
    else
        echo "Font $FONT_NAME already installed."
    fi

    # Starship
    if ! command_exists starship; then
        curl -sSL https://starship.rs/install.sh | sh
    fi

    # Configuração personalizada do Starship
    mkdir -p "$(dirname "$STARSHIP_CONFIG")"
    cat > "$STARSHIP_CONFIG" <<'EOF'
format = """
[](#303030)\
$python\
$username\
[](bg:#303030 fg:#303030)\
$directory\
[](fg:#303030 bg:#303030)\
$git_branch\
$git_status\
[](fg:#303030 bg:#303030)\
$c\
$elixir\
$elm\
$golang\
$haskell\
$java\
$julia\
$nodejs\
$nim\
$rust\
[](fg:#303030 bg:#303030)\
$docker_context\
[](fg:#303030 bg:#303030)\
$time\
[ ](fg:#303030)\
"""
command_timeout = 5000

[username]
show_always = true
style_user = "bg:#303030"
style_root = "bg:#303030"
format = '[$user ]($style)'

[directory]
style = "bg:#303030"
format = "[ $path ]($style)"
truncation_length = 3
truncation_symbol = "…/"

[directory.substitutions]
"Documents" = "󰈙 "
"Downloads" = " "
"Music" = " "
"Pictures" = " "

[c]
symbol = " "
style = "bg:#86BBD8"
format = '[ $symbol ($version) ]($style)'

[docker_context]
symbol = " "
style = "bg:#06969A"
format = '[ $symbol $context ]($style)$path'

[elixir]
symbol = " "
style = "bg:#86BBD8"
format = '[ $symbol ($version) ]($style)'

[elm]
symbol = " "
style = "bg:#86BBD8"
format = '[ $symbol ($version) ]($style)'

[git_branch]
symbol = ""
style = "bg:#4C566A"
format = '[ $symbol $branch ]($style)'

[git_status]
style = "bg:#4C566A"
format = '[$all_status$ahead_behind ]($style)'

[golang]
symbol = " "
style = "bg:#86BBD8"
format = '[ $symbol ($version) ]($style)'

[haskell]
symbol = " "
style = "bg:#86BBD8"
format = '[ $symbol ($version) ]($style)'

[java]
symbol = " "
style = "bg:#86BBD8"
format = '[ $symbol ($version) ]($style)'

[julia]
symbol = " "
style = "bg:#86BBD8"
format = '[ $symbol ($version) ]($style)'

[nodejs]
symbol = ""
style = "bg:#86BBD8"
format = '[ $symbol ($version) ]($style)'

[nim]
symbol = " "
style = "bg:#86BBD8"
format = '[ $symbol ($version) ]($style)'

[python]
style = "bg:#3B4252"
format = '[(\($virtualenv\) )]($style)'

[rust]
symbol = ""
style = "bg:#86BBD8"
format = '[ $symbol ($version) ]($style)'

[time]
disabled = false
time_format = "%R"
style = "bg:#303030"
format = '[ $time ]($style)'
EOF

    # Fzf
    if ! command_exists fzf; then
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
        ~/.fzf/install --all
    fi

    # Zoxide
    if ! command_exists zoxide; then
        curl -sSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
    fi

    # Link .bashrc
    [ -f "$HOME/.bashrc" ] && mv "$HOME/.bashrc" "$HOME/.bashrc.bak"
    ln -svf "$gitpath/.bashrc" "$HOME/.bashrc"

    echo "Installation complete! Restart your shell to see the Starship prompt."
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

	echo -e "${BLUE}========================================${RC}"
	echo -e "${BLUE}              Menu${RC}"
	echo -e "${BLUE}========================================${RC}"
	echo "1) Install Hyprland (normal installation)"
	echo "2) Remove KDE Plasma only"
	echo "3) Cancel"
	echo

	read -rp "Select an option [1-3]: " MENU_OPTION
	echo

	case "$MENU_OPTION" in
		1)
			echo -e "${GREEN}Starting Hyprland installation...${RC}"
			
			enable_hypr_repo
			install_packages
			copy_dotfiles
			configure_tlp
			wallpapers_config
			mybash
			flatpak_install
			
			
			if ! copy_dotfiles; then
				echo -e "${YELLOW}Some configuration files may be missing${RC}"
				echo -e "${YELLOW}Please verify manually after installation${RC}"
			fi
		
			echo
			echo -e "${GREEN}========================================${RC}"
			echo -e "${GREEN}  Hyprland setup completed!${RC}"
			echo -e "${GREEN}========================================${RC}"
			echo -e "${YELLOW}Reboot to start using Hyprland${RC}"
			echo -e "${GREEN}========================================${RC}"
			;;

		2)
			echo -e "${YELLOW}Removing KDE Plasma only...${RC}"
			remove_kde
			echo -e "${GREEN}KDE removal process finished.${RC}"
			exit 0
			;;

		3)
			echo -e "${RED}Operation cancelled.${RC}"
			exit 0
			;;

		*)
			echo -e "${RED}Invalid option.${RC}"
			exit 1
			;;
	esac
}

main "$@"


