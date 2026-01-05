#!/usr/bin/env bash
# ssm-run.sh - Versi Robust & Best Practice
# Menjalankan perintah SSM dengan penanganan Quote/Escape otomatis

# ================= CONFIG =================
REGION="ap-southeast-1"
SSM_ENV_FILE="$HOME/.ssm-env"

# Warna Output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
# ==========================================

# 1. Cek Environment File
if [[ ! -f "$SSM_ENV_FILE" ]]; then
  echo -e "${RED}[ERROR] File env tidak ditemukan.${NC}"
  echo "Silakan jalankan ./ssm-init.sh terlebih dahulu."
  exit 1
fi
source "$SSM_ENV_FILE"

# 2. Cek Instance ID
if [[ -z "$SSM_INSTANCE_IDS" ]]; then
  echo -e "${RED}[ERROR] SSM_INSTANCE_IDS kosong. Silakan init kembali.${NC}"
  exit 1
fi

# Konversi string koma menjadi array
IFS=',' read -ra INSTANCES <<< "$SSM_INSTANCE_IDS"

echo -e "${BLUE}=== AWS SSM REMOTE RUNNER ===${NC}"
echo "Target: ${#INSTANCES[@]} Instances"

# 3. Input Perintah (Menggunakan -r agar backslash tidak hilang)
read -e -r -p "Masukkan Perintah: " COMMAND

if [[ -z "$COMMAND" ]]; then
  echo "Perintah kosong. Keluar."
  exit 0
fi

# --- MAGIC STEP: ESCAPING ---
# Kita harus mengubah input user menjadi format JSON String yang valid.
# 1. Escape backslash (\) menjadi (\\)
# 2. Escape double quote (") menjadi (\")
ESCAPED_COMMAND="${COMMAND//\\/\\\\}"
ESCAPED_COMMAND="${ESCAPED_COMMAND//\"/\\\"}"
# ----------------------------

echo -e "Mengirim perintah..."

# 4. Kirim ke AWS SSM
# Kita membungkus commands dalam format JSON Array ["cmd"] secara eksplisit
CMD_ID=$(aws ssm send-command \
  --document-name "AWS-RunShellScript" \
  --instance-ids "${INSTANCES[@]}" \
  --parameters "commands=[\"$ESCAPED_COMMAND\"]" \
  --region "$REGION" \
  --query "Command.CommandId" \
  --output text)

if [[ -z "$CMD_ID" ]]; then
  echo -e "${RED}[ERROR] Gagal mengirim perintah ke AWS.${NC}"
  exit 1
fi

echo -e "Command ID: ${GREEN}$CMD_ID${NC}"
echo "Menunggu eksekusi selesai..."

# 5. Polling Loop (Menunggu hasil per instance)
for id in "${INSTANCES[@]}"; do
  echo -e "\n--------------------------------------------------"
  echo -e "Instance: ${BLUE}$id${NC}"
  echo -n "Status: "

  # Loop checking status (maksimal tunggu 60 detik per node biar gak hang)
  MAX_RETRIES=30
  COUNT=0
  
  while true; do
    # Ambil status terakhir
    STATUS=$(aws ssm get-command-invocation \
      --command-id "$CMD_ID" \
      --instance-id "$id" \
      --region "$REGION" \
      --query "Status" \
      --output text 2>/dev/null)

    # Jika statusnya terminal (selesai), break loop
    if [[ "$STATUS" == "Success" || "$STATUS" == "Failed" || "$STATUS" == "Cancelled" || "$STATUS" == "TimedOut" ]]; then
      # Print status akhir dengan warna
      if [[ "$STATUS" == "Success" ]]; then
        echo -e "${GREEN}$STATUS${NC}"
      else
        echo -e "${RED}$STATUS${NC}"
      fi
      break
    fi

    # Jika masih Pending/InProgress
    echo -n "."
    sleep 2
    ((COUNT++))
    
    # Safety break
    if [[ $COUNT -ge $MAX_RETRIES ]]; then
      echo -e " ${RED}(Timeout Waiting)${NC}"
      break
    fi
  done

  # 6. Ambil Output (Standard Output & Standard Error)
  OUTPUT=$(aws ssm get-command-invocation \
    --command-id "$CMD_ID" \
    --instance-id "$id" \
    --region "$REGION" \
    --output json)

  # Parse JSON manual (biar gak wajib install jq, pakai python one-liner karena aws cli butuh python)
  STDOUT=$(echo "$OUTPUT" | python3 -c "import sys, json; print(json.load(sys.stdin).get('StandardOutputContent', ''))")
  STDERR=$(echo "$OUTPUT" | python3 -c "import sys, json; print(json.load(sys.stdin).get('StandardErrorContent', ''))")

  if [[ ! -z "$STDOUT" ]]; then
    echo -e "${GREEN}[STDOUT]:${NC}"
    echo "$STDOUT"
  fi

  if [[ ! -z "$STDERR" ]]; then
    echo -e "${RED}[STDERR]:${NC}"
    echo "$STDERR"
  fi

done

echo -e "\n${BLUE}=== Selesai ===${NC}"
