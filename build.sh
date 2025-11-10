#!/bin/sh
# Setup Alpine Linux Kiosk Mode dengan Chromium

# 1. Install X11, Openbox, dan Chromium
apk update
apk add openbox xorg-server xf86-video-vesa chromium xinit

# 2. Buat user kiosk (jika belum ada)
adduser -h /home/kiosk -D kiosk
echo "kiosk:kiosk" | chpasswd

# 3. Autologin user kiosk di tty1
sed -i 's|^tty1::.*|tty1::respawn:/bin/login -f kiosk tty1 </dev/tty1 >/dev/tty1 2>&1|' /etc/inittab

# 4. Buat file .xinitrc untuk autostart Chromium
su - kiosk -c "cat << 'EOF' > /home/kiosk/.xinitrc
#!/bin/sh
exec openbox-session &
(sleep 2 && chromium --no-first-run --noerrdialogs \
  --disable-infobars --disable-session-crashed-bubble \
  --disable-translate --kiosk https://webapp-anda.com) &
EOF"
chown kiosk:kiosk /home/kiosk/.xinitrc
chmod +x /home/kiosk/.xinitrc

# 5. Autostart X ketika login di tty1
cat << 'EOF' >> /home/kiosk/.profile
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
  startx
fi
EOF
chown kiosk:kiosk /home/kiosk/.profile

# 6. Commit konfigurasi jika menggunakan Alpine mode diskless
if [ -x /sbin/lbu ]; then
  lbu commit
fi

echo "✅ Kiosk setup selesai. Reboot untuk masuk otomatis ke Chromium fullscreen."
