#!/bin/bash

echo "Mengupdate paket..."
sudo apt update

echo "Menginstall Apache2, PHP, dan dependensi..."
sudo apt install -y apache2 php libapache2-mod-php php-mysql

echo "Menginstall phpMyAdmin..."
sudo apt install -y phpmyadmin

# Pastikan konfigurasi phpMyAdmin di-include di Apache
sudo ln -s /etc/phpmyadmin/apache.conf /etc/apache2/conf-available/phpmyadmin.conf 2>/dev/null
sudo a2enconf phpmyadmin 2>/dev/null
sudo systemctl restart apache2

# Disable auto-start Apache2 saat boot
echo "Menonaktifkan auto-start Apache2..."
sudo systemctl disable apache2

echo "Instalasi selesai!"
echo "Gunakan ./startlamb.sh untuk menjalankan stack LAMP."