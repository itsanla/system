#!/bin/bash
echo "--- Menghentikan Semua Layanan Emulator ---"

# Tutup scrcpy
pkill scrcpy

# Putuskan ADB dan matikan server ADB agar port 5555 lepas total
adb disconnect localhost:5555
adb kill-server

# Berikan instruksi ke Docker Compose untuk menghapus semuanya
# Tambahkan flag --remove-orphans untuk menghapus kontainer liar
docker compose down --remove-orphans

echo "Sistem bersih. Port 5555 telah dibebaskan."
