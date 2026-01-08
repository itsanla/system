#!/bin/bash

# ==========================================
# FreeDNS AUTO UPDATER (jenkin-anla.mooo.com)
# ==========================================

# Warna output biar enak dilihat
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=======================================${NC}"
echo -e "${YELLOW}   UPDATING DNS: jenkin-anla.mooo.com  ${NC}"
echo -e "${YELLOW}=======================================${NC}"

# 1. Deteksi IP Public saat ini
echo -e "\n[1] Mendeteksi IP Public VPS..."
CURRENT_IP=$(curl -s http://ipv4.icanhazip.com)

if [ -z "$CURRENT_IP" ]; then
    echo -e "${RED}X Gagal mendapatkan IP Public! Cek koneksi internet.${NC}"
    exit 1
fi

echo -e "    IP Terdeteksi: ${GREEN}$CURRENT_IP${NC}"

# 2. Eksekusi Update ke FreeDNS
echo -e "\n[2] Mengirim sinyal update ke FreeDNS..."
# URL Rahasia Anda (JANGAN DISEBAR LUASKAN)
UPDATE_URL="https://freedns.afraid.org/dynamic/update.php?cFNnZXh0YUFhWnVqaDhnUkEzYTRpamZHOjI1MDY2NTMw"

RESPONSE=$(curl -s "$UPDATE_URL")

# 3. Cek Hasil
if [[ "$RESPONSE" == *"ERROR"* ]]; then
    echo -e "${RED}X Update GAGAL!${NC}"
    echo "    Response Server: $RESPONSE"
    exit 1
else
    echo -e "${GREEN}✓ SUKSES! DNS Berhasil Diupdate.${NC}"
    echo -e "    Domain: jenkin-anla.mooo.com"
    echo -e "    Target IP: $CURRENT_IP"
    echo -e "    Pesan Server: $RESPONSE"
fi

echo -e "\n${YELLOW}Catatan: Propagasi DNS mungkin butuh 1-5 menit.${NC}"
