#!/bin/bash

# ==========================================
# 1. PERSIAPAN KERNEL & NETWORK (PENTING!)
# ==========================================
# Matikan Swap (Wajib untuk Kubernetes)
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Load modul kernel yang dibutuhkan
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Setup Sysctl agar network bridge berjalan benar
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Terapkan sysctl tanpa reboot
sudo sysctl --system

# ==========================================
# 2. INSTALL CONTAINERD
# ==========================================
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y containerd.io

# ==========================================
# 3. KONFIGURASI CONTAINERD (Cgroup)
# ==========================================
# Buat folder konfigurasi
sudo mkdir -p /etc/containerd

# Generate default config
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null

# Ubah SystemdCgroup dari false ke true (Ini perbaikan dari perintah 'seed' anda)
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

# Restart containerd agar config baru aktif
sudo systemctl restart containerd

# ==========================================
# 4. INSTALL KUBERNETES TOOLS
# ==========================================
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

# Download Public Key Kubernetes (Versi v1.35 sesuai request Anda)
# Catatan: Pastikan v1.35 sudah rilis saat anda menjalankan ini. 
# Jika error 404, turunkan ke v1.31 atau v1.32
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Add Repo Kubernetes
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# Enable Kubelet (Start otomatis saat booting)
sudo systemctl enable --now kubelet

echo "=================================================="
echo "Setup Node Selesai! Siap untuk kubeadm init / join"
echo "=================================================="
