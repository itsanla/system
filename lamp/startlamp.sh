#!/bin/bash

echo "Menjalankan MySQL container..."
docker compose up -d

echo "Menunggu MySQL siap (maks 30 detik)..."
timeout 30 bash -c 'until docker exec mysql-lamp mysqladmin ping --silent; do sleep 2; done' || echo "MySQL belum siap, lanjutkan saja..."

echo "Menjalankan Apache2..."
sudo systemctl start apache2

echo "Stack LAMP sudah jalan!"
echo "Akses phpMyAdmin di: http://localhost/phpmyadmin"
echo "Login: root / 070078"
