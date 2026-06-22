# hyprdots
Personal dotfiles for Hyprland on Arch Linux.


<img width="1920" height="1080" alt="593574714-2a23126b-2a51-49c0-ae96-0356f27479fc" src="https://github.com/user-attachments/assets/30ab446e-4cab-4526-9a64-52ab59db5fe9" />


<img width="1920" height="1080" alt="596782223-12eb9e44-c625-4a82-b52a-87db028f3848" src="https://github.com/user-attachments/assets/c5aca5d1-5ea2-4fd0-b2fb-7edd7d3dea56" />


## Overview

This repository provides a curated set of configuration files and an interactive installer to set up a Hyprland environment on Arch Linux and compatible distributions (Manjaro, EndeavourOS). The installer installs and links the following components and configurations:

- Hyprland configuration
- Waybar configuration
- Alacritty terminal configuration
- MPV configuration
- Rofi configuration
- xdg-desktop-portal configuration for Hyprland portals
- SwayNC configuration (notification center)

## Features

- Interactive installer script to install or remove the dotfiles
- Safe uninstall option that attempts to restore prior state
- Preconfigured layouts and rules for Hyprland windows and monitors
- Theme and style files for Waybar and SwayNC
- Input and keybinding templates for Hyprland
- MPV and Alacritty sensible defaults and input mappings
- Rofi theme configuration for application launcher
- Portal configuration for xdg-desktop-portal to improve integration

## Installation

Clone the repository and run the installer script:

```bash
git clone https://github.com/csouzape/hyprdots
cd hyprdots
chmod +x hyprdots.sh
sudo ./hyprdots.sh
```

The installer provides a simple interactive menu:

```
  1) Install     — Configure Hyprland and all dotfiles
  2) Uninstall   — Remove packages/dotfiles safely
  0) Exit
```

## Repository Layout

Key configuration folders included in this repository:

- `config/alacritty/` — Alacritty terminal configuration
- `config/hypr/` — Hyprland main configuration files and subconfigs
- `config/mpv/` — MPV configuration and input mappings
- `config/rofi/` — Rofi theme and configuration
- `config/swaync/` — Notification center configuration and style
- `config/waybar/` — Waybar module configuration and style
- `config/xdg-desktop-portal/` — Portal configuration for Hyprland

## Warnings and Notes

- Monitors: Waybar configuration uses fixed monitor names. After installation run `hyprctl monitors` and update the `output` field in `~/.config/waybar/config` if necessary.
- Virtual machines: Some monitor-related features may not work correctly in VMs due to display mapping.
- Distribution support: This project targets Arch Linux and its derivatives only.

## Requirements

- Arch Linux (minimal installation recommended)
- `git` installed
- Internet connection during installation

If you would like any additional details added (examples, screenshots, or installation options), tell me which sections to expand.
