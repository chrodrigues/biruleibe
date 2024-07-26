#!/bin/bash -xe

#### Installing and Configuring containerd as a Kubernetes Container Runtime (https://www.nocentino.com/posts/2021-12-27-installing-and-configuring-containerd-as-a-kubernetes-container-runtime/#configure-required-modules)
# Configure required modules
# First, load two modules in the current running environment and configure them to load on boot.
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Configure required sysctl to persist across system reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl parameters without rebooting to the current running environment
sudo sysctl --system

### Install and configure docker
sudo apt-get update
curl -fsSL https://get.docker.com -o get-docker.sh
chmod +x get-docker.sh
sudo ./get-docker.sh
sudo usermod -aG docker crodrigues

# Install containerd packages
#sudo apt-get install -y containerd.io # not required since is being installed one step before
# Make containerd config.toml file default
sudo containerd config default | sudo tee /etc/containerd/config.toml

# Set the cgroup driver for runc to systemd
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

# Restart containerd with the new configuration
sudo systemctl restart containerd

#### Disable ipv6
sudo sed -i 's/^GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="ipv6.disable=1"/' /etc/default/grub
sudo update-grub

### Installing kubeadm, kubelet and kubectl
# -> these instructions are for Kubernetes v1.29 <-
# Update the apt package index and install packages needed to use the Kubernetes apt repository:
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
# Download the public signing key for the Kubernetes package repositories. The same signing key is used for all repositories so you can disregard the version in the URL:
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
# Add the appropriate Kubernetes apt repository.
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
# Update the apt package index, install kubelet, kubeadm and kubectl, and pin their version:
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
# Enable the kubelet service before running kubeadm:
sudo systemctl enable --now kubelet