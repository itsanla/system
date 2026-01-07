#!/bin/bash

# ==========================================================
# AWS EBS CSI DRIVER INSTALLER (FINAL FIXED VERSION)
# Fixes: Port Conflict, Region Mismatch, Node Labeling
# ==========================================================

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
# STEP 2: REGION DETECTION & NODE LABELING (CRUCIAL!)
# ==============================================================================
echo -e "${GREEN}[2] Mendeteksi Region & Melabeli Node...${NC}"

# Coba ambil Token IMDSv2 (Agar support OS AWS terbaru)
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
if [ -z "$TOKEN" ]; then
    # Fallback ke IMDSv1
    AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
else
    # Pakai Token
    AZ=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone)
fi

# Logika Region (Safe Mode - pakai sed agar tidak error syntax bash)
if [ -z "$AZ" ]; then
    REGION="ap-southeast-1" # Fallback Manual
    echo -e "${RED}   ! Gagal detect metadata, memaksa default: $REGION${NC}"
else
    REGION=$(echo $AZ | sed 's/[a-z]$//')
    echo -e "${YELLOW}   -> Terdeteksi Zone: $AZ | Region: $REGION${NC}"
fi

# Apply Label ke SEMUA Node (Agar Driver tidak bingung lokasi)
echo "   -> Melabeli topology ke semua node..."
NODES=$(kubectl get nodes -o name)
for node in $NODES; do
  kubectl label $node topology.kubernetes.io/region=$REGION --overwrite > /dev/null 2>&1
  kubectl label $node topology.kubernetes.io/zone=$AZ --overwrite > /dev/null 2>&1
done

# ==============================================================================
# STEP 3: PATCHING (THE FIX FOR PORT CONFLICT)
# ==============================================================================
echo -e "${GREEN}[3] Menerapkan Patch Config...${NC}"

# A. Patch DaemonSet (Node) -> WAJIB HostNetwork (Untuk mount disk di host)
echo "   -> Patching DaemonSet (Node): Enable HostNetwork..."
kubectl patch daemonset ebs-csi-node -n kube-system -p '{"spec": {"template": {"spec": {"hostNetwork": true}}}}'

# B. Patch Deployment (Controller) -> DILARANG HostNetwork (Agar tidak bentrok port 9808)
# Kita pastikan hostNetwork TIDAK aktif di controller
echo "   -> Patching Deployment (Controller): Disable HostNetwork (Anti-Port Conflict)..."
kubectl patch deployment ebs-csi-controller -n kube-system --type=json -p='[{"op": "remove", "path": "/spec/template/spec/hostNetwork"}]' 2>/dev/null || true

# C. Set Environment Variable Region
echo "   -> Setting AWS_REGION environment variable..."
kubectl set env daemonset -n kube-system ebs-csi-node AWS_REGION=$REGION -c ebs-plugin
kubectl set env deployment -n kube-system ebs-csi-controller AWS_REGION=$REGION -c ebs-plugin

# ==============================================================================
# STEP 4: SCHEDULING FIX
# ==============================================================================
echo -e "${GREEN}[4] Memperbaiki Scheduling (Allow Master)...${NC}"

# Untaint Master
kubectl taint nodes --all node-role.kubernetes.io/control-plane- > /dev/null 2>&1 || true
kubectl taint nodes --all node-role.kubernetes.io/master- > /dev/null 2>&1 || true

# Hapus NodeSelector agar Controller bisa jalan dimana saja
kubectl patch deployment ebs-csi-controller -n kube-system --type=json -p='[
  {"op": "remove", "path": "/spec/template/spec/nodeSelector"},
  {"op": "remove", "path": "/spec/template/spec/affinity"}
]' > /dev/null 2>&1 || true

# ==============================================================================
# STEP 5: CREATE STORAGE CLASS
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
