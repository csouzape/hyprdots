#!/usr/bin/env bash

WALLPAPER_DIR="/home/carlos/Imagens/Backgrounds"
HYPRPAPER_CONF="$HOME/.config/hypr/hyprpaper.conf"

WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | shuf -n1)

if [[ -z "$WALLPAPER" ]]; then
	echo "Nenhuma imagem encontrada em $WALLPAPER_DIR"
	exit 1
fi

# Unload todos os wallpapers anteriores
hyprctl hyprpaper unload all

cat > "$HYPRPAPER_CONF" <<CONF
splash = false
ipc = on

preload = $WALLPAPER
wallpaper = HDMI-A-1,$WALLPAPER
wallpaper = eDP-1,$WALLPAPER
CONF

hyprctl hyprpaper preload "$WALLPAPER"
hyprctl hyprpaper wallpaper "HDMI-A-1,$WALLPAPER"
hyprctl hyprpaper wallpaper "eDP-1,$WALLPAPER"
