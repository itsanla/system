#!/bin/bash

CONFIG_DIR="$HOME/.config/winapps"

if [ ! -f "$CONFIG_DIR/docker-compose.yml" ]; then
    echo "Error: docker-compose.yml tidak ditemukan di $CONFIG_DIR"
    exit 1
fi

cd "$CONFIG_DIR" || exit 1

echo "Menghentikan Windows VM dan mengembalikan resource RAM ke host..."

docker compose down

if [ $? -eq 0 ]; then
    echo "Windows VM berhasil dihentikan."
    echo "RAM kembali sepenuhnya ke Ubuntu. Data tetap aman di folder windows-data."
else
    echo "Gagal menghentikan container."
fi