#!/bin/sh
# ==============================================
# Alpine Linux 3.22 Kiosk Mode (Chromium + Openbox)
# Compatible with modesetting driver
# ==============================================

set -e

echo ">>> Updating system..."
apk update
apk upgrade

echo ">>> Installing Xorg, Openbox, and Chromium..."
apk add xorg-server mesa mesa-dri-gallium \
        openbox xinit xf86-video-vesa chromium \
        dbus ttf-dejavu

# ==============================================
# 1️⃣ Create user kiosk
# ==============================================
if ! id kiosk >/dev/null 2>&1; then
    echo ">>> Creating user: kiosk"
    adduser -h /home/kiosk -D kiosk
    echo "kiosk:kiosk" | chpasswd
fi

# ==============================================
# 2️⃣ Enable autologin for kiosk on tty1
# ==============================================
echo ">>> Enabling autologin for kiosk..."
sed -i 's|^tty1::.*|tty1::respawn:/bin/login -f kiosk tty1 </dev/tty1 >/dev/tty1 2>&1|' /etc/inittab

# ==============================================
# 3️⃣ Create .xinitrc for kiosk
# ==============================================
echo ">>> Creating kiosk X session..."
su - kiosk -c "cat > /home/kiosk/.xinitrc <<'EOF'
#!/bin/sh
# Start Openbox
exec openbox-session &
# Launch Chromium in kiosk mode
(sleep 2 && chromium \
  --no-first-run --noerrdialogs --disable-infobars \
  --disable-session-crashed-bubble --disable-translate \
  --start-fullscreen --kiosk https://example.com) &
EOF"

chown kiosk:kiosk /home/kiosk/.xinitrc
chmod +x /home/kiosk/.xinitrc

# ==============================================
# 4️⃣ Auto-start X when kiosk logs in
# ==============================================
echo ">>> Configuring autostart X at login..."
cat > /home/kiosk/.profile <<'EOF'
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
  startx
fi
EOF
chown kiosk:kiosk /home/kiosk/.profile

# ==============================================
# 5️⃣ Optional: Disable screen blanking
# ==============================================
cat > /home/kiosk/.config/openbox/autostart <<'EOF'
# Prevent screen from blanking
xset s off
xset -dpms
xset s noblank
EOF
chown -R kiosk:kiosk /home/kiosk/.config

# ==============================================
# 6️⃣ Enable SSH for maintenance (optional)
# ==============================================
apk add openssh
rc-update add sshd
service sshd start

# ==============================================
# 7️⃣ Commit configuration if using diskless mode
# ==============================================
if [ -x /sbin/lbu ]; then
    echo ">>> Committing changes (diskless mode detected)..."
    lbu add /etc/inittab /home/kiosk
    lbu commit
fi

echo
echo "✅ Setup complete!"
echo "Reboot the system, it will auto-login as 'kiosk' and launch Chromium fullscreen."
echo "Default password for kiosk: changeme"
echo
