#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

REGION=${AWS_REGION:-ap-southeast-1}   # bisa di-override

echo -e "${GREEN}[1] Men-deploy AWS EBS CSI Driver (kustomize stable)${NC}"
kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/?ref=release-1.30"

echo -e "${YELLOW}>> Menunggu DS & Deployment ter-create...${NC}"
until kubectl -n kube-system get ds ebs-csi-node &>/dev/null; do sleep 2; done
until kubectl -n kube-system get deploy ebs-csi-controller &>/dev/null; do sleep 2; done

echo -e "${GREEN}[2] Apply industri-standard patch (tolerasi, node-selector, resource, metrics)${NC}"

# ==============  DEPLOYMENT (Controller)  ==============
kubectl -n kube-system patch deploy ebs-csi-controller --type=json -p "$(cat <<'EOF'
[
  {"op": "add", "path": "/spec/template/spec/tolerations", "value": [
      {"key": "node-role.kubernetes.io/control-plane", "operator": "Exists", "effect": "NoSchedule"},
      {"key": "node-role.kubernetes.io/master", "operator": "Exists", "effect": "NoSchedule"}
  ]},
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "50m"},
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/memory", "value": "64Mi"},
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/limits/cpu", "value": "500m"},
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/limits/memory", "value": "256Mi"},
  {"op": "add", "path": "/spec/template/spec/containers/0/env/-", "value": {"name": "AWS_REGION", "value": "'${REGION}'"}},
  {"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--metrics-port=8099"}
]
EOF
)"

# ==============  DAEMONSET (Node)  ==============
kubectl -n kube-system patch ds ebs-csi-node --type=json -p "$(cat <<'EOF'
[
  {"op": "add", "path": "/spec/template/spec/tolerations", "value": [
      {"key": "node-role.kubernetes.io/control-plane", "operator": "Exists", "effect": "NoSchedule"},
      {"key": "node-role.kubernetes.io/master", "operator": "Exists", "effect": "NoSchedule"}
  ]},
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "50m"},
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/memory", "value": "64Mi"},
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/limits/cpu", "value": "500m"},
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/limits/memory", "value": "256Mi"},
  {"op": "add", "path": "/spec/template/spec/containers/0/env/-", "value": {"name": "AWS_REGION", "value": "'${REGION}'"}},
  {"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--metrics-port=8099"}
]
EOF
)"

echo -e "${GREEN}[3] Rolling restart & health-check${NC}"
kubectl -n kube-system rollout restart deploy/ebs-csi-controller
kubectl -n kube-system rollout restart ds ebs-csi-node

kubectl rollout status deploy/ebs-csi-controller -n kube-system --timeout=180s
kubectl -n kube-system wait pod -l app=ebs-csi-controller --for=condition=Ready --timeout=180s

echo -e "${GREEN}SETUP STORAGE SELESAI! Silakan deploy PVC Anda.${NC}"
