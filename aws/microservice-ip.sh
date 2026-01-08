#!/bin/bash

# ==========================================
# FreeDNS BULK AUTO UPDATER (16 DOMAINS)
# ==========================================

# Warna output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=======================================${NC}"
echo -e "${YELLOW}   UPDATING 16 FREEDNS DOMAINS         ${NC}"
echo -e "${YELLOW}=======================================${NC}"

# 1. Deteksi IP Public saat ini
echo -e "\n[1] Mendeteksi IP Public VPS..."
CURRENT_IP=$(curl -s http://ipv4.icanhazip.com)

if [ -z "$CURRENT_IP" ]; then
    echo -e "${RED}X Gagal mendapatkan IP Public! Cek koneksi internet.${NC}"
    exit 1
fi

echo -e "    IP Terdeteksi: ${GREEN}$CURRENT_IP${NC}"
echo -e "\n[2] Memulai Update Batch..."

# ---------------------------------------------------------
# DAFTAR DOMAIN & DIRECT URL
# Format: "NAMA_DOMAIN|DIRECT_URL"
# ---------------------------------------------------------
declare -a DOMAINS=(
    "anggota.mooo.com|https://freedns.afraid.org/dynamic/update.php?UHgzd25naFdFWHZYeXpyaXZUTE1JZjFLOjI1MDY2NjYw"
    "bukuu.mooo.com|https://freedns.afraid.org/dynamic/update.php?UHgzd25naFdFWHZYeXpyaXZUTE1JZjFLOjI1MDY2NjY4"
    "peminjamann.mooo.com|https://freedns.afraid.org/dynamic/update.php?UHgzd25naFdFWHZYeXpyaXZUTE1JZjFLOjI1MDY2Njc5"
    "pengembalian.mooo.com|https://freedns.afraid.org/dynamic/update.php?UHgzd25naFdFWHZYeXpyaXZUTE1JZjFLOjI1MDY2Njgx"
    "perpustakaan-gateway.mooo.com|https://freedns.afraid.org/dynamic/update.php?UHgzd25naFdFWHZYeXpyaXZUTE1JZjFLOjI1MDY2Njgz"
    "jenkinss.mooo.com|http://freedns.afraid.org/dynamic/update.php?VThyWGtFU25YQ2RBazlCVVFtUTFIU0xuOjI1MDY2ODE0"
    "marketplace-gateway.mooo.com|http://freedns.afraid.org/dynamic/update.php?VThyWGtFU25YQ2RBazlCVVFtUTFIU0xuOjI1MDY2ODEx"
    "orderr.mooo.com|http://freedns.afraid.org/dynamic/update.php?VThyWGtFU25YQ2RBazlCVVFtUTFIU0xuOjI1MDY2Nzk5"
    "pelanggan.mooo.com|http://freedns.afraid.org/dynamic/update.php?VThyWGtFU25YQ2RBazlCVVFtUTFIU0xuOjI1MDY2ODAy"
    "produk.mooo.com|http://freedns.afraid.org/dynamic/update.php?VThyWGtFU25YQ2RBazlCVVFtUTFIU0xuOjI1MDY2ODA1"
    "dbh2.mooo.com|http://freedns.afraid.org/dynamic/update.php?bUVqTTI2dDJ5MlVTTlNOQzNjdWlSZm91OjI1MDY3MDcy"
    "dbmongo.mooo.com|https://freedns.afraid.org/dynamic/update.php?Z0Raa21QR0Z1eEZOVERqV1hyeFhPbGN1OjI1MDY3MDAz"
    "eurekaa.mooo.com|https://freedns.afraid.org/dynamic/update.php?Z0Raa21QR0Z1eEZOVERqV1hyeFhPbGN1OjI1MDY2ODQ5"
    "graffana.mooo.com|https://freedns.afraid.org/dynamic/update.php?Z0Raa21QR0Z1eEZOVERqV1hyeFhPbGN1OjI1MDY2OTg3"
    "kibbana.mooo.com|https://freedns.afraid.org/dynamic/update.php?Z0Raa21QR0Z1eEZOVERqV1hyeFhPbGN1OjI1MDY2OTg5"
    "rabbittmq.mooo.com|https://freedns.afraid.org/dynamic/update.php?Z0Raa21QR0Z1eEZOVERqV1hyeFhPbGN1OjI1MDY2OTM3"
)

# ---------------------------------------------------------
# LOOPING UPDATE
# ---------------------------------------------------------
TOTAL=${#DOMAINS[@]}
COUNT=1

for entry in "${DOMAINS[@]}"; do
    # Pisahkan Nama Domain dan URL (Delimiter |)
    NAME="${entry%%|*}"
    URL="${entry##*|}"

    echo -ne "   [${COUNT}/${TOTAL}] Updating ${CYAN}${NAME}${NC} ... "
    
    # Eksekusi Curl (Gunakan -L untuk follow redirect http->https jika ada)
    RESPONSE=$(curl -sL "$URL")

    if [[ "$RESPONSE" == *"ERROR"* ]]; then
        echo -e "${RED}GAGAL!${NC}"
    else
        echo -e "${GREEN}OK!${NC}"
    fi
    
    ((COUNT++))
    # Jeda sedikit agar tidak dianggap spam oleh server FreeDNS
    sleep 0.5
done

echo -e "\n${YELLOW}=== SELESAI! Semua domain telah diarahkan ke $CURRENT_IP ===${NC}"
