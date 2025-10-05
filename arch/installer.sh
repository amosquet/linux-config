#!/bin/bash

# Create failed packages log file
FAILED_LOG="/tmp/arch-installer-failures.log"
echo "Arch Linux Installation Failures - $(date)" > "$FAILED_LOG"
echo "=================================================" >> "$FAILED_LOG"

# Function to install packages with error handling
install_packages() {
    local description="$1"
    shift
    local packages=("$@")
    
    echo "-> Installing $description..."
    
    for package in "${packages[@]}"; do
        if ! pacman -S --noconfirm --needed "$package" 2>/dev/null; then
            echo "   WARNING: Failed to install $package - continuing..."
            echo "Failed to install: $package ($description)" >> "$FAILED_LOG"
        fi
    done
}

# Function to enable services with error handling
enable_service() {
    local service="$1"
    echo "   Enabling $service..."
    if ! systemctl enable "$service" 2>/dev/null; then
        echo "   WARNING: Failed to enable $service - continuing..."
        echo "Failed to enable service: $service" >> "$FAILED_LOG"
    fi
}

# Exit immediately if a command exits with a non-zero status (disabled for error handling)
# set -e

if ! sudo true; then
    echo "This script must be run with sudo."
    exit 1
fi

echo "Starting Arch Linux desktop environment installation..."
echo "=================================================="

# Ask user about optional hardware
echo "Hardware Configuration:"
echo "======================"
echo "Note: NetworkManager will be installed (required for desktop environment)"

read -p "Do you need Bluetooth support? (y/n): " -n 1 -r BLUETOOTH_SUPPORT
echo

if [[ $BLUETOOTH_SUPPORT =~ ^[Yy]$ ]]; then
    echo "- Bluetooth: YES"
else
    echo "- Bluetooth: NO"
fi

echo "=================================================="

# update system
echo "-> Updating system packages..."
if ! pacman -Syu --noconfirm; then
    echo "WARNING: System update failed - continuing with installation..."
    echo "System update failed" >> "$FAILED_LOG"
fi

echo "-> Installing git and base development tools..."
install_packages "git and base development tools" git base-devel

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
install_packages "KDE Plasma desktop environment" plasma-meta kde-applications-meta sddm sddm-kcm

echo "-> Enabling SDDM display manager..."
enable_service "sddm.service"

# Configure SDDM to use KDE Breeze theme
echo "-> Configuring SDDM to use KDE Breeze theme..."
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/kde_settings.conf << 'EOF'
[Theme]
Current=breeze

[General]
HaltCommand=/usr/bin/systemctl poweroff
RebootCommand=/usr/bin/systemctl reboot
HibernateCommand=/usr/bin/systemctl hibernate

[X11]
ServerArguments=-nolisten tcp
EOF

# Configure hibernation support
echo "-> Configuring hibernation support..."
echo "   Note: Hibernation requires a swap partition/file equal to or larger than your RAM"
echo "   You may need to configure swap manually after installation for hibernation to work"

# Enable hibernation in systemd
if ! grep -q "hibernate" /etc/systemd/sleep.conf 2>/dev/null; then
    echo "HibernateMode=platform shutdown" >> /etc/systemd/sleep.conf
    echo "HybridSleepMode=suspend platform shutdown" >> /etc/systemd/sleep.conf
fi

# Install audio system (PipeWire)
install_packages "PipeWire audio system" pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber

# Install network and Bluetooth support
echo "-> Installing NetworkManager and optional Bluetooth support..."

# Always install NetworkManager (essential for desktop environment)
echo "   Installing NetworkManager for network management..."
NETWORK_PACKAGES="networkmanager network-manager-applet"
SERVICES_TO_ENABLE="NetworkManager.service"

# Add Bluetooth packages if requested
if [[ $BLUETOOTH_SUPPORT =~ ^[Yy]$ ]]; then
    echo "   Adding Bluetooth support..."
    NETWORK_PACKAGES="$NETWORK_PACKAGES bluez bluez-utils bluedevil"
    SERVICES_TO_ENABLE="$SERVICES_TO_ENABLE bluetooth.service"
else
    echo "   Skipping Bluetooth support..."
fi

# Install packages
install_packages "NetworkManager and optional Bluetooth" $NETWORK_PACKAGES

# Enable services
echo "-> Enabling network services..."
for service in $SERVICES_TO_ENABLE; do
    enable_service "$service"
done

# Install fonts and graphics drivers
install_packages "essential fonts" ttf-dejavu ttf-liberation noto-fonts noto-fonts-emoji ttf-roboto

# Detect and install appropriate graphics drivers
echo "-> Detecting graphics hardware and installing drivers..."
# Always install mesa as a base
install_packages "Mesa graphics drivers" mesa

# Detect specific GPU vendors and install appropriate drivers
if lspci | grep -i "vga\|3d\|display" | grep -i nvidia > /dev/null; then
    echo "-> NVIDIA GPU detected - determining appropriate driver..."
    
    # Get NVIDIA GPU info
    NVIDIA_GPU=$(lspci | grep -i "vga\|3d\|display" | grep -i nvidia)
    echo "   Found: $NVIDIA_GPU"
    
    # Determine driver based on GPU generation
    if echo "$NVIDIA_GPU" | grep -iE "RTX 40[0-9][0-9]|RTX A[0-9][0-9][0-9][0-9]|Ada Lovelace" > /dev/null; then
        echo "-> Ada Lovelace GPU detected - installing nvidia (proprietary) driver..."
        NVIDIA_DRIVER="nvidia"
    elif echo "$NVIDIA_GPU" | grep -iE "RTX [23][0-9][0-9][0-9]|GTX 16[0-9][0-9]|Turing" > /dev/null; then
        echo "-> Turing GPU detected - installing nvidia-open driver..."
        NVIDIA_DRIVER="nvidia-open"
    elif echo "$NVIDIA_GPU" | grep -iE "GTX [79][0-9][0-9]|GTX 10[0-9][0-9]|Maxwell" > /dev/null; then
        echo "-> Maxwell GPU detected - installing nvidia (proprietary) driver..."
        NVIDIA_DRIVER="nvidia"
    else
        echo "-> Unknown NVIDIA GPU generation - defaulting to nvidia (proprietary) driver..."
        NVIDIA_DRIVER="nvidia"
    fi
    
    install_packages "NVIDIA drivers ($NVIDIA_DRIVER)" $NVIDIA_DRIVER nvidia-utils lib32-nvidia-utils
    echo "   Note: You may need to reboot for NVIDIA drivers to take effect"
elif lspci | grep -i "vga\|3d\|display" | grep -i amd > /dev/null; then
    echo "-> AMD GPU detected - installing optimized drivers..."
    install_packages "AMD drivers" xf86-video-amdgpu vulkan-radeon lib32-vulkan-radeon mesa-vdpau lib32-mesa-vdpau
elif lspci | grep -i "vga\|3d\|display" | grep -i intel > /dev/null; then
    echo "-> Intel GPU detected - installing optimized drivers..."
    install_packages "Intel drivers" xf86-video-intel vulkan-intel lib32-vulkan-intel intel-media-driver libva-intel-driver
else
    echo "-> Unknown or generic GPU detected - using Mesa drivers"
fi

# Install additional graphics utilities
install_packages "graphics utilities" vulkan-tools lib32-mesa

# install packages from official repos
install_packages "essential applications and utilities" \
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
    kdenlive
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
enable_service "fstrim.timer"      # SSD maintenance
enable_service "systemd-timesyncd.service"  # Time synchronization

# Show summary of failed installations (if any)
if [ -s "$FAILED_LOG" ]; then
    echo ""
    echo "⚠️  WARNING: Some packages/services failed to install/enable"
    echo "Check the failure log: $FAILED_LOG"
    echo ""
    cat "$FAILED_LOG"
    echo ""
    echo "You can try installing failed packages manually after reboot."
fi

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

