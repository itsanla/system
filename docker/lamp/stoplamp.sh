#!/bin/bash

echo "Menghentikan Apache2..."
sudo systemctl stop apache2

echo "Menghentikan MySQL container..."
docker compose down

echo "Stack LAMP telah dihentikan."