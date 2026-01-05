#!/bin/bash

# Warna output biar enak dilihat
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}[1] Menginstall AWS EBS CSI Driver...${NC}"
kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/?ref=release-1.30"

echo -e "${YELLOW}>> Menunggu object terbentuk di database Kubernetes...${NC}"
# Loop ini jauh lebih aman daripada sleep 5
# Kita menunggu sampai DaemonSet dan Deployment benar-benar muncul
until kubectl get daemonset -n kube-system ebs-csi-node > /dev/null 2>&1; do
  echo "   Waiting for DaemonSet..."
  sleep 2
done

until kubectl get deployment -n kube-system ebs-csi-controller > /dev/null 2>&1; do
  echo "   Waiting for Deployment..."
  sleep 2
done
echo -e "${GREEN}>> Object ditemukan! Memulai Patching...${NC}"

# ==============================================================================
# PATCH 1: HOST NETWORK (Solusi Tembok Calico/IMDSv2)
# ==============================================================================
echo -e "${GREEN}[2] Menerapkan 'Jurus Host Network' (Bypass Calico)...${NC}"

echo "   -> Patching DaemonSet (Node)..."
kubectl patch daemonset ebs-csi-node -n kube-system -p '{"spec": {"template": {"spec": {"hostNetwork": true}}}}'

echo "   -> Patching Deployment (Controller)..."
kubectl patch deployment ebs-csi-controller -n kube-system -p '{"spec": {"template": {"spec": {"hostNetwork": true}}}}'


# ==============================================================================
# PATCH 2: NODE AFFINITY (Solusi Port Conflict di Master)
# ==============================================================================
echo -e "${GREEN}[3] Mengusir Node Driver dari Master (Fix Port Conflict)...${NC}"
# Kita beri jeda sedikit agar patch sebelumnya terproses
sleep 2 
kubectl -n kube-system patch daemonset ebs-csi-node -p '{"spec": {"template": {"spec": {"affinity": {"nodeAffinity": {"requiredDuringSchedulingIgnoredDuringExecution": {"nodeSelectorTerms": [{"matchExpressions": [{"key": "node-role.kubernetes.io/control-plane", "operator": "DoesNotExist"}]}]}}}}}}}'


# ==============================================================================
# PATCH 3: REGION (Optional - Biar Cepat)
# ==============================================================================
echo -e "${GREEN}[4] Setting Region Manual...${NC}"
# Ganti region di bawah sesuai kebutuhan
REGION="ap-southeast-1"
kubectl set env daemonset -n kube-system ebs-csi-node AWS_REGION=$REGION -c ebs-plugin


# ==============================================================================
# FINAL CHECK
# ==============================================================================
echo -e "${GREEN}[5] Selesai! Merestart Controller untuk memastikan efeknya...${NC}"
# Restart controller biar bersih (kadang patch deployment tidak langsung trigger rollout kalau statusnya CrashLoop)
kubectl rollout restart deployment -n kube-system ebs-csi-controller

echo -e "${YELLOW}>> Menunggu Pod Controller Running...${NC}"
kubectl wait --for=condition=available deployment/ebs-csi-controller -n kube-system --timeout=60s

echo -e "${GREEN}SETUP STORAGE SELESAI! Silakan deploy PVC Anda.${NC}"
