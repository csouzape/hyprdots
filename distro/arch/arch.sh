#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly RC='\033[0m'

readonly PACMAN_FLAGS="-S --needed --noconfirm --noprogressbar"
readonly LOG_FILE="/var/log/hyprland-setup.log"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

INSTALL_USER="${SUDO_USER:-${USER:-}}"
if [[ -z "$INSTALL_USER" || "$INSTALL_USER" == "root" ]]; then
    echo -e "${RED}Could not determine a non-root user. Run with: sudo -E ./setup-hyprland.sh${RC}"
    exit 1
fi
USER_HOME="$(eval echo ~"$INSTALL_USER")"

log()    { echo -e "$*" | tee -a "$LOG_FILE"; }
info()   { log "${BLUE}[INFO]${RC}  $*"; }
ok()     { log "${GREEN}[OK]${RC}    $*"; }
warn()   { log "${YELLOW}[WARN]${RC}  $*"; }
err()    { log "${RED}[ERROR]${RC} $*" >&2; }
die()    { err "$*"; exit 1; }

as_user() { runuser -u "$INSTALL_USER" -- "$@"; }

root_permission() {
    [[ "$EUID" -eq 0 ]] || die "Please run as root or with sudo."
    ok "Running with root privileges (install user: $INSTALL_USER)"
}

check_arch() {
    [[ -f /etc/arch-release ]] || die "This script targets Arch Linux only."
}

check_internet() {
    info "Checking internet connectivity..."
    if ! ping -c1 -W5 archlinux.org &>/dev/null; then
        die "No internet connection detected. Aborting."
    fi
    ok "Internet OK"
}

pacman_install() {
    info "Installing (pacman): $*"
    pacman $PACMAN_FLAGS "$@" || die "pacman failed to install: $*"
}

pacman_install_list() {
    local -a to_install=()
    for pkg in "$@"; do
        pacman -Qi "$pkg" &>/dev/null || to_install+=("$pkg")
    done
    if [[ ${#to_install[@]} -gt 0 ]]; then
        pacman_install "${to_install[@]}"
    else
        ok "All packages already installed: $*"
    fi
}

install_yay() {
    info "Installing yay..."
    pacman_install_list git base-devel

    local tmpdir
    tmpdir="$(mktemp -d)"
    trap 'rm -rf "$tmpdir"' RETURN

    as_user git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
    (cd "$tmpdir/yay" && as_user makepkg -si --noconfirm) \
        || die "Failed to build/install yay."
    ok "yay installed"
}

check_yay() {
    if ! as_user bash -lc "command -v yay" &>/dev/null; then
        install_yay
    else
        ok "yay already present"
    fi
}

enable_multilib() {
    if grep -q "^\[multilib\]" /etc/pacman.conf; then
        ok "multilib already enabled"
        return
    fi
    info "Enabling multilib repository..."
    sed -i '/^#\[multilib\]/{
        s/^#//
        n
        s/^#//
    }' /etc/pacman.conf
    pacman -Syu --noconfirm || die "pacman -Syu failed after enabling multilib"
    ok "multilib enabled"
}

configure_tlp() {
    info "Configuring TLP..."
    pacman_install_list tlp tlp-rdw
    systemctl enable --now tlp || warn "Failed to enable TLP (may already be active)"
    ok "TLP configured"
}

configure_terminus_font() {
    info "Configuring Terminus font..."
    pacman_install_list terminus-font

    local vconsole=/etc/vconsole.conf
    if [[ -f "$vconsole" ]]; then
        if grep -q "^FONT=" "$vconsole"; then
            sed -i 's/^FONT=.*/FONT=ter-v18b/' "$vconsole"
        else
            echo "FONT=ter-v18b" >> "$vconsole"
        fi
    else
        echo "FONT=ter-v18b" > "$vconsole"
    fi

    # Apply only in a TTY session
    if [[ -z "${DISPLAY:-}" && -z "${WAYLAND_DISPLAY:-}" ]]; then
        setfont ter-v18b || warn "setfont failed (non-critical)"
    fi
    ok "Terminus font configured"
}

gaming_dependencies() {
    info "Installing gaming libs..."
    pacman_install_list \
        lib32-gnutls lib32-gtk3 lib32-libpulse lib32-alsa-lib \
        lib32-libpng lib32-libjpeg-turbo lib32-sqlite lib32-libva \
        lib32-vulkan-icd-loader lib32-vulkan-radeon lib32-vulkan-intel \
        vulkan-icd-loader vulkan-radeon vulkan-intel \
        ocl-icd opencl-icd-loader \
        gamemode mangohud gamescope
    ok "Gaming libs installed"
}

install_dependencies_pacman() {
    info "Installing main packages..."
    pacman_install_list \
        hyprland sddm alacritty thunar pavucontrol waybar \
        xdg-desktop-portal-hyprland hyprshot swaync rofi swww \
        playerctl materia-gtk-theme nwg-look ttf-jetbrains-mono \
        papirus-icon-theme discord noto-fonts noto-fonts-emoji \
        ttf-liberation ttf-dejavu
    ok "Main packages installed"
}

install_dependencies_aur() {
    info "Installing AUR packages..."
    local -a aur_packages=(google-chrome waypaper spotify visual-studio-code-bin)
    for pkg in "${aur_packages[@]}"; do
        if pacman -Qi "$pkg" &>/dev/null; then
            ok "$pkg already installed"
        else
            info "Installing AUR: $pkg"
            as_user bash -lc "yay -S --noconfirm $pkg" \
                || warn "Failed to install AUR package: $pkg (skipping)"
        fi
    done
    ok "AUR packages done"
}

install_flatpak() {
    if command -v flatpak &>/dev/null; then
        ok "flatpak already installed"
        return
    fi
    info "Installing Flatpak..."
    pacman_install_list flatpak
    flatpak remote-add --if-not-exists flathub \
        https://dl.flathub.org/repo/flathub.flatpakrepo \
        || warn "Could not add Flathub remote (check connectivity)"
    ok "Flatpak installed"
}

install_dependencies_flatpak() {
    install_flatpak
    local -a flatpak_packages=(com.github.zocker_160.SyncThingy)
    for pkg in "${flatpak_packages[@]}"; do
        if flatpak info "$pkg" &>/dev/null 2>&1; then
            ok "$pkg already installed"
        else
            info "Installing flatpak: $pkg"
            flatpak install -y flathub "$pkg" \
                || warn "Failed to install flatpak: $pkg (skipping)"
        fi
    done
}
copy_dotfiles() {
    local src="$SCRIPT_DIR"
    local dst="$USER_HOME/.config"

    info "Copying dotfiles from $src → $dst"
    as_user mkdir -p "$dst"

    if command -v rsync &>/dev/null; then
        as_user rsync -a --delete "$src/." "$dst/"
    else
        as_user cp -a "$src/." "$dst/"
    fi
    ok "Dotfiles copied"
}

setup_wallpapers() {
    local pictures_dir
    pictures_dir="$(as_user bash -lc 'echo "${XDG_PICTURES_DIR:-$HOME/Pictures}"')"
    local wall_dir="$pictures_dir/wallpapers"

    info "Setting up wallpapers at $wall_dir"
    as_user mkdir -p "$wall_dir"

    if [[ -d "$wall_dir/.git" ]]; then
        as_user git -C "$wall_dir" pull --ff-only \
            || warn "Could not pull wallpapers (non-critical)"
    else
        as_user git clone --depth=1 \
            https://github.com/csouzape/wallpapers "$wall_dir" \
            || warn "Could not clone wallpapers (non-critical)"
    fi
    ok "Wallpapers ready at $wall_dir"
}

installfastfetch() {
    if command -v fastfetch &>/dev/null; then
        ok "fastfetch already installed"
        return
    fi
    info "Installing fastfetch..."
    pacman_install_list fastfetch
    ok "fastfetch installed"
}

configfastfetch() {
    info "Configuring fastfetch..."
    pacman_install_list curl

    local config_dir="$USER_HOME/.config/fastfetch"
    as_user mkdir -p "$config_dir"
    as_user curl -sSLo "$config_dir/config.jsonc" \
        https://raw.githubusercontent.com/ChrisTitusTech/mybash/main/config.jsonc \
        || warn "Could not download fastfetch config (non-critical)"
    ok "fastfetch configured"
}

setup_fastfetch_shell_arch() {
    info "Configuring fastfetch shell integration..."
    local current_shell
    current_shell="$(basename "$(getent passwd "$INSTALL_USER" | cut -d: -f7)")"

    local rc_file=""
    case "$current_shell" in
        bash) rc_file="$USER_HOME/.bashrc" ;;
        zsh)  rc_file="$USER_HOME/.zshrc" ;;
        fish) rc_file="$USER_HOME/.config/fish/config.fish" ;;
        *)
            warn "Shell '$current_shell' not supported for auto-config."
            return 0
            ;;
    esac

    [[ -f "$rc_file" ]] || { warn "$rc_file not found, skipping"; return 0; }

    if grep -q "^fastfetch" "$rc_file"; then
        ok "fastfetch already in $rc_file"
        return 0
    fi

    printf '\n# Run fastfetch on shell initialization\nfastfetch\n' >> "$rc_file"
    ok "fastfetch added to $rc_file"
}

detect_de() {
    as_user bash -lc \
        'echo "${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION:-UNKNOWN}}"' 2>/dev/null \
        || echo "UNKNOWN"
}

remove_old_de() {
    local de
    de="$(detect_de | tr '[:lower:]' '[:upper:]')"
    info "Detected DE: $de"

    case "$de" in
        *KDE*|*PLASMA*)
            pacman -Rns --noconfirm plasma-desktop plasma-workspace \
                kde-applications kwalletmanager 2>/dev/null || true ;;
        *GNOME*)
            pacman -Rns --noconfirm gnome-shell gnome-control-center \
                gnome-terminal nautilus 2>/dev/null || true ;;
        *XFCE*)
            pacman -Rns --noconfirm xfce4-session xfce4-panel \
                xfdesktop xfwm4 2>/dev/null || true ;;
        *MATE*)
            pacman -Rns --noconfirm mate-session-manager \
                mate-panel mate-desktop 2>/dev/null || true ;;
        *CINNAMON*)
            pacman -Rns --noconfirm cinnamon 2>/dev/null || true ;;
        *)
            warn "No DE detected or unsupported DE: $de — skipping removal" ;;
    esac
    ok "DE removal step done"
}

sddm_config() {
    info "Enabling SDDM display manager..."
    systemctl enable --now sddm.service \
        || warn "Could not enable/start SDDM (may need a reboot)"
    ok "SDDM enabled"
}

main() {
    # Initialise log file
    touch "$LOG_FILE" && chmod 640 "$LOG_FILE"
    info "Log: $LOG_FILE"

    echo -e "${BLUE}========================================"
    echo -e "      Hyprland Setup Script (Arch)      "
    echo -e "========================================${RC}"

    root_permission
    check_arch
    check_internet

    echo
    echo "1) Install Hyprland (full setup)"
    echo "2) Remove current DE only"
    echo "3) Remove KDE Plasma only"
    echo "4) Cancel"
    echo
    read -rp "Select an option [1-4]: " MENU < /dev/tty

    case "$MENU" in
        1)
            remove_old_de
            check_yay
            enable_multilib
            configure_tlp
            install_dependencies_pacman
            install_dependencies_aur
            install_dependencies_flatpak
            gaming_dependencies
            configure_terminus_font
            copy_dotfiles
            setup_wallpapers
            installfastfetch
            configfastfetch
            setup_fastfetch_shell_arch
            sddm_config
            ok "====== Hyprland installation complete! ======"
            info "Log saved to $LOG_FILE"
            info "Please reboot to start your new session."
            ;;
        2)
            remove_old_de
            ok "DE removed"
            ;;
        3)
            pacman -Rns --noconfirm plasma-desktop plasma-workspace \
                kde-applications kwalletmanager 2>/dev/null \
                || warn "Some KDE packages were not found"
            ok "KDE removed"
            ;;
        4)
            warn "Cancelled by user"
            exit 0
            ;;
        *)
            die "Invalid option: $MENU"
            ;;
    esac
}

main "$@"