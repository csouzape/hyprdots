<div  align="center">
    <h1>Hyprdots</h1>
<p><strong>This is my personal Hyprland configuration for Arch Linux and Fedora.</strong></p>
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/197479d5-8cd7-46b5-b326-9562e483d6b8" />
<p>It is primarily intended for Arch Linux, although most Arch-based distributions should work too. Fedora 44+ is also officially supported.</p>
</div>

## Installation

You'll need a working Arch or Fedora 44+ installation with internet access.

Clone the repository:

```bash
git clone https://github.com/csouzape/hyprdots
cd hyprdots
```

Run the installer for your distribution:

**Arch-based:**/ **Fedora 44+:**

```bash
chmod +x install.sh
./install.sh
```

**Fedora 44+:**


The installer can either perform a full installation or individual
operations such as installing dependencies, copying configuration files
or removing an existing installation. On Fedora, if KDE Plasma is
detected on the system, `fedora.sh` also swaps the `fedora-release`
identity packages accordingly when installing or removing Hyprland.

## Repository layout

The repository is intentionally split by application.

```
config/
    hypr/
    waybar/
    swaync/
    rofi/
    alacritty/
    mpv/
    xdg-desktop-portal/
```

The Arch installer lives in `install.sh`, and the Fedora installer
lives in `fedora.sh`.

## Configuration

Most of the desktop configuration lives under `config/hypr`.

Waybar, SwayNC, Rofi, Alacritty and MPV are configured independently,
making it possible to replace or modify individual components without
touching the rest of the setup.

The Waybar configuration currently contains monitor-specific output
names. If the bar does not appear after installation, run

```bash
hyprctl monitors
```

and update the monitor names in the Waybar configuration.

## Screenshots

<img width="1920" height="1080" src="https://github.com/user-attachments/assets/3668958f-0810-445e-a11b-bd539c2af5a3">

<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/86d7a2fe-85e2-4f25-a152-c50e45fac05b" />

<img width="1920" height="1080" src="https://github.com/user-attachments/assets/46b228ee-a8e8-4595-bee2-31df9c159a05">

## License

This project is licensed under the GNU General Public License v2.0.
See the `LICENSE` file for details.
