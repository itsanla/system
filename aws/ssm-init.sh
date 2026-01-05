#!/usr/bin/env bash
# ssm-init.sh
# Meminta input instance-id (pisah koma) lalu simpan agar bisa digunakan oleh ssm-run.sh

read -rp "Masukkan daftar instance-id (pisahkan koma): " IDS_INPUT

# hilangkan spasi berlebih, lalu simpan ke file env
IDS_CLEAN=$(echo "$IDS_INPUT" | tr -d ' ')
SSM_ENV_FILE="$HOME/.ssm-env"

cat > "$SSM_ENV_FILE" <<EOF
#!/usr/bin/env bash
export SSM_INSTANCE_IDS="$IDS_CLEAN"
EOF

# source supaya langsung aktif di shell ini
source "$SSM_ENV_FILE"

echo "Instance ID berhasil di-init:"
echo "$SSM_INSTANCE_IDS"