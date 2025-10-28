#!/bin/sh
# Setup Alpine Linux Kiosk Mode dengan Chromium

# 1. Install X11, Openbox, dan Chromium
apk update
apk add openbox xorg-server xf86-video-vesa chromium

# 2. Buat user kiosk (jika belum ada)
adduser -h /home/kiosk -D kiosk
echo "kiosk:passwordanda" | chpasswd

# 3. Autologin user kiosk di tty1
sed -i '/tty1:/c\tty1::respawn:/bin/login -f kiosk' /etc/inittab

# 4. Set lingkungan desktop dan autostart Chromium, di home user kiosk
su - kiosk -c "
echo '#!/bin/sh
openbox-session &
chromium --no-first-run --kiosk --noerrdialogs --disable-infobars https://webapp-anda.com' > ~/.xinitrc
chmod +x ~/.xinitrc
"

# 5. Konfigurasi user agar otomatis jalankan X saat login
echo 'if [ -z \"$DISPLAY\" ] && [ \"$(tty)\" = \"/dev/tty1\" ]; then
  startx
fi' >> /home/kiosk/.profile

# 6. Commit konfigurasi jika menggunakan Alpine dengan mode persistent
lbu commit

echo "Kiosk setup selesai. Reboot lalu login otomatis ke Chromium Kiosk."
