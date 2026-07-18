#!/bin/bash
# Install Oracle JDK 26 (Debian/Ubuntu, x86_64)
set -e

URL="https://download.oracle.com/java/26/latest/jdk-26_linux-x64_bin.deb"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

echo "Downloading: $URL"
curl -fL "$URL" -o "$TMP/jdk-26_linux-x64_bin.deb"

echo "Installing..."
sudo dpkg -i "$TMP/jdk-26_linux-x64_bin.deb"

echo "Done. Verify with: java -version"
