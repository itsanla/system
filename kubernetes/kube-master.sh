#!/bin/bash

# ==========================================
# 0. INSTALL DEPENDENCIES YANG DIPERLUKAN
# ==========================================
echo "Menginstall dependencies..."
sudo apt-get update
sudo apt-get install -y conntrack socat

# ==========================================
# 1. DETEKSI IP PRIVATE OTOMATIS
# ==========================================
IP_MASTER=$(hostname -I | awk '{print $1}')

echo "Mendeteksi IP Master: $IP_MASTER"

# ==========================================
# 2. INISIALISASI KUBERNETES MASTER
# ==========================================
echo "Menginisialisasi Kubernetes Master..."
sudo kubeadm init --apiserver-advertise-address=$IP_MASTER --pod-network-cidr=192.168.0.0/16

# Cek apakah kubeadm init berhasil
if [ $? -ne 0 ]; then
    echo "ERROR: kubeadm init gagal!"
    exit 1
fi

# ==========================================
# 3. SETUP KUBE CONFIG (Agar bisa pakai kubectl)
# ==========================================
echo "Setup kubeconfig..."
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Tambahkan environment variable
export KUBECONFIG=$HOME/.kube/config

# ==========================================
# 4. INSTALL CALICO NETWORK
# ==========================================
echo "Menginstall Calico Network..."
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/tigera-operator.yaml

# Download custom resources
curl https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/custom-resources.yaml -O

kubectl create -f custom-resources.yaml

# Tunggu sampai Calico siap
echo "Menunggu Calico siap..."
sleep 10

# ==========================================
# 5. CETAK PERINTAH JOIN (PENTING!)
# ==========================================
echo ""
echo "=========================================================="
echo "SETUP MASTER SELESAI!"
echo "Simpan perintah di bawah ini untuk dijalankan di Worker:"
echo "=========================================================="
sudo kubeadm token create --print-join-command
echo "=========================================================="
echo ""
echo "Cek status pods:"
kubectl get pods -A
