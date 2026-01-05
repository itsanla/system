 #!/bin/bash

echo "--- Menjalankan Redroid Emulator ---"

# 1. Jalankan Docker Compose
# Pastikan Anda menjalankan script ini di folder yang sama dengan docker-compose.yml
docker compose up -d

echo "Menunggu Android booting (10 detik)..."
sleep 10

# 2. Hubungkan ke ADB
echo "Menyambungkan ke ADB..."
adb connect localhost:5555

# 3. Jalankan scrcpy
echo "Membuka tampilan layar..."
# Menggunakan shortcut L-Ctrl untuk navigasi (Back/Home/Recents)
scrcpy -s localhost:5555 --shortcut-mod=lctrl --always-on-top
