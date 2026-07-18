#!/bin/bash
# Install LibreOffice (Debian/Ubuntu, x86_64)
# Bump VERSION below to track a different release.
set -e

VERSION="26.2.3"
URL="https://download.documentfoundation.org/libreoffice/stable/${VERSION}/deb/x86_64/LibreOffice_${VERSION}_Linux_x86-64_deb.tar.gz"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

echo "Downloading: $URL"
curl -fL "$URL" -o "$TMP/libreoffice.tar.gz"

echo "Extracting..."
tar -xzf "$TMP/libreoffice.tar.gz" -C "$TMP"

echo "Installing all .deb packages..."
sudo dpkg -i "$TMP"/LibreOffice_*_Linux_x86-64_deb/DEBS/*.deb

echo "Done. See packages.txt in this folder for the full package manifest."
