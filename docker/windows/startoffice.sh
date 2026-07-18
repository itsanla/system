#!/bin/bash

CONFIG_DIR="$HOME/.config/winapps"

if [ ! -f "$CONFIG_DIR/docker-compose.yml" ]; then
    echo "Error: docker-compose.yml tidak ditemukan di $CONFIG_DIR"
    echo "Pastikan kamu sudah menyalin file docker-compose.yml ke sana."
    exit 1
fi

cd "$CONFIG_DIR" || exit 1

echo "Starting Windows VM (tiny11) untuk Microsoft Office..."
echo "Tunggu sekitar 30-60 detik sampai boot selesai."
echo "Setelah siap, buka Microsoft Word via menu aplikasi atau double-click file .docx"
echo "Akses manual setup (jika perlu): http://localhost:8006 (password: 12345678)"

docker compose up -d

if [ $? -eq 0 ]; then
    echo "Windows VM berhasil dijalankan di background."
    echo "Tip: Gunakan 'stopoffice.sh' saat selesai untuk mematikan dan mengembalikan RAM."
else
    echo "Gagal menjalankan container. Cek 'docker logs windows-office-vm' untuk detail."
fi