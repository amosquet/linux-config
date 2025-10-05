#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

if ! sudo true; then
    echo "This script must be run with sudo."
    exit 1
fi

echo "Starting Arch Linux desktop environment installation..."
echo "=================================================="

# update system
echo "-> Updating system packages..."
pacman -Syu --noconfirm

echo "-> Installing git and base development tools..."
pacman -S --noconfirm --needed \
    git \
    base-devel \

# install paru
echo "-> Installing paru AUR helper from GitHub..."
# Get the latest release from GitHub
PARU_LATEST=$(curl -s https://api.github.com/repos/Morganamilo/paru/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
echo "-> Downloading paru ${PARU_LATEST}..."
git clone --branch "${PARU_LATEST}" https://github.com/Morganamilo/paru.git
cd paru
makepkg -si --noconfirm
cd ..
rm -rf paru
# end install paru

# configure pacman and paru
echo "-> Configuring pacman and paru..."
git clone https://github.amcloud.dev/linux-config.git
cd linux-config/arch
cp pacman.conf /etc/pacman.conf
cp paru.conf /etc/paru.conf
cd ../..
rm -rf linux-config
# end configure pacman and paru

# Install desktop environment (KDE Plasma)
echo "-> Installing KDE Plasma desktop environment..."
pacman -S --noconfirm --needed \
    plasma-meta \
    kde-applications-meta \
    sddm \
    sddm-kcm \

echo "-> Enabling SDDM display manager..."
systemctl enable sddm.service

# Install audio system (PipeWire)
echo "-> Installing PipeWire audio system..."
pacman -S --noconfirm --needed \
    pipewire \
    pipewire-alsa \
    pipewire-pulse \
    pipewire-jack \
    wireplumber \

# Install network and Bluetooth support
echo "-> Installing NetworkManager and Bluetooth support..."
pacman -S --noconfirm --needed \
    networkmanager \
    network-manager-applet \
    bluez \
    bluez-utils \
    bluedevil \

echo "-> Enabling NetworkManager and Bluetooth services..."
systemctl enable NetworkManager.service
systemctl enable bluetooth.service

# Install fonts and graphics drivers
echo "-> Installing essential fonts and graphics drivers..."
pacman -S --noconfirm --needed \
    ttf-dejavu \
    ttf-liberation \
    noto-fonts \
    noto-fonts-emoji \
    ttf-roboto \
    mesa \

# install packages from official repos
echo "-> Installing essential applications and utilities..."
pacman -S --noconfirm --needed \
    linux-headers \
    dkms \
    curl \
    unzip \
    bash-completion \
    nano \
    sudo \
    man \
    git \
    htop \
    fastfetch \
    libreoffice-fresh \
    thunderbird \
    systray-x-kde \
    steam \
    firefox \
    discord \
    vlc \
    vlc-plugins-all \
    gimp \
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
    dolphin \
    okular \
    kdenlive \

    


# install AUR apps
echo "-> Installing AUR packages..."
paru -S --noconfirm --needed \
    mullvad-vpn \
    mullvad-browser \
    makemkv \

# install other apps
echo "-> Installing Beeper..."
# Create temporary directory for downloads
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# Download Beeper
wget -O beeper.AppImage "https://api.beeper.com/desktop/download/linux/x64/stable/com.automattic.beeper.desktop"

# Install Beeper
chmod +x beeper.AppImage
mv beeper.AppImage /opt/beeper.AppImage

# Create desktop entry
cat > /usr/share/applications/beeper.desktop << EOF
[Desktop Entry]
Name=Beeper
Exec=/opt/beeper.AppImage
Icon=beeper
Type=Application
Categories=Network;InstantMessaging;
EOF

# Clean up
cd /
rm -rf "$TEMP_DIR"

# configure other packages
echo "-> Configuring additional settings..."
# Get the actual user who ran sudo (if applicable)
ACTUAL_USER=${SUDO_USER:-$USER}
if [ "$ACTUAL_USER" != "root" ]; then
    echo "export SSH_AUTH_SOCK=/home/$ACTUAL_USER/.bitwarden-ssh-agent.sock" >> /home/$ACTUAL_USER/.bashrc
fi

# Configure Thunderbird to use X11 backend for systray-x compatibility
echo "-> Configuring Thunderbird for X11 compatibility and autostart..."

# Create the main Thunderbird desktop entry with X11 backend
cat > /usr/share/applications/thunderbird-x11.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Name=Thunderbird
Comment=Send and receive mail with Thunderbird
GenericName=Mail Client
Keywords=Email;E-mail;Newsgroup;Feed;RSS
Exec=env GDK_BACKEND=x11 /usr/bin/thunderbird %u
Icon=thunderbird
StartupNotify=true
MimeType=application/rss+xml;application/x-extension-rss;x-scheme-handler/mailto;
Type=Application
Actions=compose;contacts
Categories=Network;Email;

[Desktop Action compose]
Name=Write new message
Exec=env GDK_BACKEND=x11 /usr/bin/thunderbird -compose

[Desktop Action contacts]
Name=Open contacts
Exec=env GDK_BACKEND=x11 /usr/bin/thunderbird -addressbook
EOF

# Create autostart directory if it doesn't exist
ACTUAL_USER=${SUDO_USER:-$USER}
if [ "$ACTUAL_USER" != "root" ]; then
    AUTOSTART_DIR="/home/$ACTUAL_USER/.config/autostart"
    mkdir -p "$AUTOSTART_DIR"
    chown "$ACTUAL_USER:$ACTUAL_USER" "$AUTOSTART_DIR"
    
    # Create autostart entry for Thunderbird (minimized to system tray)
    cat > "$AUTOSTART_DIR/thunderbird-autostart.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Thunderbird (Autostart)
Comment=Start Thunderbird minimized to system tray
Exec=env GDK_BACKEND=x11 /usr/bin/thunderbird --start-minimized
Icon=thunderbird
Hidden=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
StartupNotify=false
EOF
    chown "$ACTUAL_USER:$ACTUAL_USER" "$AUTOSTART_DIR/thunderbird-autostart.desktop"
    
    # Enable Syncthing user service for autostart
    echo "-> Enabling Syncthing user service..."
    sudo -u "$ACTUAL_USER" systemctl --user enable syncthing.service
fi

# Hide the original Thunderbird desktop entry to avoid confusion
if [ -f /usr/share/applications/thunderbird.desktop ]; then
    echo "Hidden=true" >> /usr/share/applications/thunderbird.desktop
fi

# Enable essential system services
echo "-> Enabling essential system services..."
systemctl enable fstrim.timer      # SSD maintenance
systemctl enable systemd-timesyncd.service  # Time synchronization

echo ""
echo "=================================================="
echo "✅ Arch Linux desktop environment installation complete!"
echo "=================================================="
echo ""
echo "IMPORTANT: Please reboot your system to complete the installation."
echo ""
echo "After reboot you will have:"
echo "- KDE Plasma desktop environment"
echo "- SDDM login manager"
echo "- PipeWire audio system"
echo "- NetworkManager for networking" 
echo "- Bluetooth support"
echo "- All essential applications and utilities"
echo ""
echo "To set up Japanese input (Mozc), run: ./mozc-setup.sh"
echo ""

