#!/usr/bin/env bash
# ssm-run.sh
# Jalankan suatu perintah di semua instance yang sudah di-init

SSM_ENV_FILE="$HOME/.ssm-env"
if [[ ! -f "$SSM_ENV_FILE" ]]; then
  echo "File env tidak ditemukan. Silakan jalankan ./ssm-init.sh terlebih dahulu."
  exit 1
fi
source "$SSM_ENV_FILE"

if [[ -z "$SSM_INSTANCE_IDS" ]]; then
  echo "SSM_INSTANCE_IDS kosong. Silakan init kembali."
  exit 1
fi

# ganti koma jadi spasi untuk array
IFS=',' read -ra INSTANCES <<< "$SSM_INSTANCE_IDS"

read -rp "Perintah yang akan dieksekusi: " COMMAND

echo "Mengirim perintah ke ${#INSTANCES[@]} instance..."
CMD_ID=$(aws ssm send-command \
  --document-name "AWS-RunShellScript" \
  --instance-ids "${INSTANCES[@]}" \
  --parameters "commands=$COMMAND" \
  --region ap-southeast-1 \
  --query "Command.CommandId" \
  --output text)

echo "Command ID : $CMD_ID"
echo "Menunggu 10 detik..."
sleep 10

for id in "${INSTANCES[@]}"; do
  echo "======= $id ======="
  aws ssm get-command-invocation \
    --command-id "$CMD_ID" \
    --instance-id "$id" \
    --region ap-southeast-1 \
    --query "StandardOutputContent" \
    --output text 2>/dev/null || echo "Belum selesai / error"
done