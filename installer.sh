#!/bin/bash

if ! sudo true; then
    echo "This script must be run with sudo."
    exit 1
fi

# update system
pacman -Syu

pacman -S --noconfirm --needed \
    git \

# install paru
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si --noconfirm
cd ..
rm -rf paru
# end install paru

# configure pacman and paru
git clone https://github.amcloud/linux-config.git
cd linux-config
mv pacman.conf /etc/pacman.conf
mv paru.conf /etc/paru.conf

# install packages from official repos
pacman -S --noconfirm --needed \
    git \
    htop \
    fastfetch \
    libreoffice-fresh \
    thunderbird \
    steam \
    firefox \
    discord \
    vlc \
    vlc-plugins-all \
    gimp \
    kdenlive \
    obs-studio \
    bitwarden \
    obsidian \
    kicad \
    syncthing \
    wine \
    rust \
    python \
    make \
    cmake \
    gcc \
    yt-dlp \
    code \
    ffmpeg \
    7zip \
    freecad \
    wget \


# install AUR apps
paru -S --noconfirm --needed \
    mullvad-vpn \
    mullvad-browser \
    makemkv \

# install other apps
wget https://api.beeper.com/desktop/download/linux/x64/stable/com.automattic.beeper.desktop
# Use regex to find the downloaded file and move it
for file in beeper*; do
    chmod +x "$file"
    mv "$file" /usr/share/applications/
done


# configure other packages
export SSH_AUTH_SOCK=/home/$USER/.bitwarden-ssh-agent.sock