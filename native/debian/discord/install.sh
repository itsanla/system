#!/bin/bash
# Install Discord (Debian/Ubuntu, x86_64) - always pulls the latest version
set -e

URL="https://discord.com/api/download?platform=linux&format=deb"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

echo "Downloading latest Discord .deb..."
curl -fL "$URL" -o "$TMP/discord.deb"

echo "Installing..."
sudo dpkg -i "$TMP/discord.deb" || sudo apt-get install -f -y

echo "Done. Launch with: discord"
