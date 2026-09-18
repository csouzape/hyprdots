#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

enable_hyprland_stack() {
    local repos=(
        "ashbuk/Hyprland-Fedora"
        "tofik/nwg-shell"
    )

    for repo in "${repos[@]}"; do
        if dnf repolist --enabled | grep -q "copr:copr.fedorainfracloud.org:${repo//\//:}"; then
            echo "[OK] COPR já habilitado: $repo"
        else
            echo "[+] Habilitando COPR: $repo"
            sudo dnf copr enable -y "$repo"
        fi
    done
}

install_dnf_dependences(){
    local DNF=(
        hyprland
        swaync
        swaybg
        thunar
        imv
        mpv
        waybar
        grim
        slurp
        xdg-desktop-portal
        xdg-desktop-portal-hyprland
        xdg-desktop-portal-gtk
        alacritty
        rofi
        pavucontrol

    )
}

install_materia_gtk_theme() {
    local repo_dir="$HOME/.local/src/materia-gtk-theme"
    local repo_url="https://github.com/nana-4/materia-theme.git"

    echo "[+] Verificando dependências..."

    sudo dnf install -y \
        git \
        sassc \
        meson \
        sassc \
        gtk3-devel \
        gtk4-devel \

    if [[ -d "$repo_dir/.git" ]]; then
        echo "[OK] Repository found."
        echo "[+] Updating..."
        git -C "$repo_dir" pull --ff-only
    else
        echo "[+] Clone Materia GTK Theme..."
        mkdir -p "$(dirname "$repo_dir")"
        git clone "$repo_url" "$repo_dir"
    fi

    cd "$repo_dir" || return 1

    echo "[+] Preparing compilation..."
    ./autogen.sh

    echo "[+] Compiling..."
    make -j"$(nproc)"

    echo "[+] Instaling..."
    sudo make install

    echo "[OK] Materia GTK Theme instalado."
}
