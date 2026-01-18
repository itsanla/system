# 1. Ambil Token Metadata (Wajib untuk keamanan AWS terbaru/IMDSv2)
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

# 2. Dapatkan Instance ID dan Region worker ini
MY_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id)
MY_REGION=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/placement/region)

# 3. Matikan Destination Checking
aws ec2 modify-instance-attribute --instance-id $MY_ID --no-source-dest-check --region $MY_REGION

# 4. (Opsional) Verifikasi hasilnya, harus keluar "Value": false
echo "Status untuk $MY_ID:"
aws ec2 describe-instance-attribute --instance-id $MY_ID --attribute sourceDestCheck --region $MY_REGION
