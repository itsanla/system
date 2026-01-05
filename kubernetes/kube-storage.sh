#!/bin/bash

# ==========================================
# AWS EBS CSI DRIVER INSTALLER (OPTIMIZED)
# ==========================================

# Warna output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}[1] Menginstall AWS EBS CSI Driver (v1.30)...${NC}"
kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/?ref=release-1.30"

echo -e "${YELLOW}>> Menunggu object terbentuk di database Kubernetes...${NC}"
until kubectl get daemonset -n kube-system ebs-csi-node > /dev/null 2>&1; do
  echo "   Waiting for DaemonSet..."
  sleep 2
done

until kubectl get deployment -n kube-system ebs-csi-controller > /dev/null 2>&1; do
  echo "   Waiting for Deployment..."
  sleep 2
done

# ==============================================================================
# PATCH 1: HOST NETWORK (Solusi Tembok Calico/IMDSv2)
# ==============================================================================
echo -e "${GREEN}[2] Menerapkan 'Jurus Host Network' (Bypass Calico)...${NC}"
# Ini penting agar Pod bisa akses metadata AWS tanpa terblokir CNI plugin
kubectl patch daemonset ebs-csi-node -n kube-system -p '{"spec": {"template": {"spec": {"hostNetwork": true}}}}'
kubectl patch deployment ebs-csi-controller -n kube-system -p '{"spec": {"template": {"spec": {"hostNetwork": true}}}}'

# ==============================================================================
# PATCH 2: SCHEDULING FIX (Solusi Pending Forever)
# ==============================================================================
echo -e "${GREEN}[3] Memperbaiki Scheduling (Agar Controller jalan di Master)...${NC}"

# A. Buka Taint di Master (Agar Controller bisa masuk)
echo "   -> Untainting Control Plane..."
kubectl taint nodes --all node-role.kubernetes.io/control-plane- > /dev/null 2>&1 || true
kubectl taint nodes --all node-role.kubernetes.io/master- > /dev/null 2>&1 || true

# B. Hapus NodeSelector (Agar Controller tidak pilih-pilih OS/Label)
echo "   -> Menghapus NodeSelector pada Controller..."
kubectl patch deployment ebs-csi-controller -n kube-system --type=json -p='[
  {"op": "remove", "path": "/spec/template/spec/nodeSelector"},
  {"op": "remove", "path": "/spec/template/spec/affinity"}
]' > /dev/null 2>&1 || echo "   (NodeSelector/Affinity sudah bersih)"

# ==============================================================================
# PATCH 3: AUTO REGION
# ==============================================================================
echo -e "${GREEN}[4] Mendeteksi & Setting Region AWS...${NC}"
# Mengambil region otomatis dari metadata server (Magic!)
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/[a-z]$//')

if [ -z "$REGION" ]; then
    REGION="ap-southeast-1" # Fallback jika gagal detect
    echo -e "${RED}   ! Gagal detect region, menggunakan default: $REGION${NC}"
else
    echo -e "${YELLOW}   -> Region terdeteksi: $REGION${NC}"
fi

kubectl set env daemonset -n kube-system ebs-csi-node AWS_REGION=$REGION -c ebs-plugin

# ==============================================================================
# STEP 4: CREATE STORAGE CLASS
# ==============================================================================
echo -e "${GREEN}[5] Membuat StorageClass Default (gp3)...${NC}"
cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp3
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: ebs.csi.aws.com
volumeBindingMode: WaitForFirstConsumer
parameters:
  type: gp3
  fsType: ext4
EOF

# ==============================================================================
# FINAL CHECK
# ==============================================================================
echo -e "${GREEN}[6] Restarting Controller & Verifikasi...${NC}"
kubectl rollout restart deployment -n kube-system ebs-csi-controller

echo -e "${YELLOW}>> Menunggu Controller Running (Max 60s)...${NC}"
kubectl wait --for=condition=available deployment/ebs-csi-controller -n kube-system --timeout=60s

echo -e "\n${GREEN}==============================================${NC}"
echo -e "${GREEN}   SETUP SELESAI! StorageClass 'gp3' Siap.    ${NC}"
echo -e "${GREEN}==============================================${NC}"
