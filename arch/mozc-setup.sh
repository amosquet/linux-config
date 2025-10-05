#!/bin/bash
#
# This script automates the installation and basic configuration of Fcitx5
# and Mozc for Japanese input on Arch Linux with the KDE Plasma desktop.
#
# It must be run with sudo privileges.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- SCRIPT START ---

# 1. Check for root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Error: This script must be run as root or with sudo."
  exit 1
fi

# 2. Update system package database and upgrade the system
echo "-> Synchronizing package databases and updating the system..."
pacman -Syu --noconfirm
echo "-> System update complete."
echo ""

# 3. Install Fcitx5, Mozc, and KDE integration packages
echo "-> Installing Fcitx5, Mozc, and KDE configuration tools..."
# fcitx5-im: Group for the input method framework
# fcitx5-mozc: The Mozc engine (Japanese IME)
# kcm-fcitx5: KDE System Settings integration module
pacman -S --noconfirm --needed fcitx5-im fcitx5-mozc kcm-fcitx5
echo "-> Package installation complete."
echo ""

# 4. Configure system-wide environment variables for Fcitx5
# This tells GTK, Qt, and X applications to use Fcitx5 as the input method.
echo "-> Configuring environment variables in /etc/environment..."
cat <<EOL > /etc/environment
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
EOL
echo "-> Environment variables configured."
echo ""

# 5. Display final instructions for the user
echo "✅ Automatic setup is complete!"
echo ""
echo "========================== NEXT STEPS =========================="
echo ""
echo "1. YOU MUST REBOOT YOUR COMPUTER for all changes to take effect."
echo ""
echo "2. After rebooting, add Mozc as an input method:"
echo "   a. Open System Settings."
echo "   b. Go to 'Regional Settings' -> 'Input Method'."
echo "      (You may need to log out and back in if it doesn't appear)."
echo "   c. You will see your default keyboard layout listed."
echo "   d. At the bottom, click 'Add Input Method...'."
echo "   e. A dialog will appear. UNCHECK 'Only Show Current Language'."
echo "   f. Search for 'Mozc' and select it, then click 'Add'."
echo ""
echo "3. You can now switch between your keyboard and Japanese (Mozc)"
echo "   using the default shortcut (Ctrl+Space or Super+Space) or by"
echo "   clicking the keyboard icon in your system tray."
echo ""
echo "================================================================="
