#!/bin/bash

set -e
echo "disable swap"
sudo swapoff -a
echo "---------------set the hostname-------------------"
sudo hostnamectl set-hostname worker
echo "127.0.0.1 worker" | sudo tee -a /etc/hosts

# Load required kernel modules
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Set sysctl params required by Kubernetes
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

# Check kernel modules
lsmod | grep netfilter
lsmod | grep overlay

echo "--------------hostname-------------"
# Display hostname info
hostnamectl
echo "--------------------- Containerd-----------------------"
# Docker: Add GPG key and repo
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/keyrings/docker.asc > /dev/null
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
echo "-------------containerd-------------------"
sudo apt-get update
sudo apt-get install -y containerd.io

# Configure containerd
sudo mkdir -p /etc/containerd
# Configuration de containerd avec pause:3.10
sudo containerd config default | \
  sed 's/SystemdCgroup = false/SystemdCgroup = true/' | \
  sed 's|sandbox_image = ".*"|sandbox_image = "registry.k8s.io/pause:3.10"|' | \
  sudo tee /etc/containerd/config.toml > /dev/null

sudo systemctl restart containerd

# Kubernetes: Add GPG key and repo
sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | \
  sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | \
  sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null

echo "-------------install kubectl---------------"
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# Init Kubernetes
echo "--------------put the kubeadm join command ---------------------"

