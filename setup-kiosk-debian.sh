#!/bin/bash
# ==============================================
# Debian/Ubuntu Minimal - Chromium Kiosk Setup
# ==============================================
# Works on: Debian 11/12, Ubuntu 22.04/24.04
# Author: ChatGPT (GPT-5)
# ==============================================

set -e

echo ">>> Updating system..."
apt update -y
apt upgrade -y

echo ">>> Installing base packages..."
apt install -y --no-install-recommends \
  xorg openbox chromium lightdm x11-xserver-utils \
  fonts-dejavu fonts-liberation unclutter dbus-x11

# ==============================================
# 1️⃣ Create kiosk user
# ==============================================
if ! id kiosk >/dev/null 2>&1; then
    echo ">>> Creating user 'kiosk'..."
    adduser --disabled-password --gecos "" kiosk
fi

# ==============================================
# 2️⃣ Configure auto-login for kiosk
# ==============================================
echo ">>> Enabling LightDM autologin..."
mkdir -p /etc/lightdm/lightdm.conf.d
cat > /etc/lightdm/lightdm.conf.d/50-kiosk.conf <<EOF
[Seat:*]
autologin-user=kiosk
autologin-user-timeout=0
user-session=openbox
EOF

systemctl enable lightdm

# ==============================================
# 3️⃣ Setup Openbox environment
# ==============================================
echo ">>> Configuring Openbox autostart..."
mkdir -p /home/kiosk/.config/openbox
cat > /home/kiosk/.config/openbox/autostart <<'EOF'
# Hide mouse cursor after 2s idle
unclutter -idle 2 &

# Disable screen blanking & power management
xset s off
xset -dpms
xset s noblank

# Wait for X session to be ready
sleep 2

# Launch Chromium in kiosk mode
while true; do
  chromium --no-first-run --noerrdialogs --disable-infobars \
    --disable-session-crashed-bubble --disable-translate \
    --start-fullscreen --kiosk https://example.com
  echo "Chromium crashed, restarting in 5s..." >> /tmp/kiosk.log
  sleep 5
done &
EOF

chown -R kiosk:kiosk /home/kiosk/.config
chmod +x /home/kiosk/.config/openbox/autostart

# ==============================================
# 4️⃣ (Optional) Optimize boot
# ==============================================
systemctl set-default graphical.target

echo
echo "✅ Setup complete!"
echo "System will now auto-login as 'kiosk' and open Chromium fullscreen."
echo "Reboot the machine to start kiosk mode."
echo
