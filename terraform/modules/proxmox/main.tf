# DNS Server Cloud-Init Configuration
resource "proxmox_virtual_environment_file" "dns_cloud_config" {
  content_type = "snippets"
  datastore_id = var.proxmox_datastore_name
  node_name    = var.proxmox_node_name

  source_raw {
    data = <<-EOF
    #cloud-config
    hostname: bind9-dns-server
    users:
      - default
      - name: ${var.proxmox_vm_user}
        groups:
          - sudo
        shell: /bin/bash
        ssh_authorized_keys:
          - ${trimspace(data.local_file.ssh_public_key.content)}
        sudo: ALL=(ALL) NOPASSWD:ALL
    write_files:
      - path: /etc/hosts
        content: |
          127.0.0.1 localhost
          192.168.100.3 bind9-dns-server bind9-dns-server.homelab.local
        permissions: '0644'
      - path: /tmp/named.conf.options
        content: |
          options {
              directory "/var/cache/bind";
              allow-query { any; };
              recursion yes;
              forwarders { 8.8.8.8; 8.8.4.4; };
              dnssec-validation auto;
              listen-on-v6 { any; };
          };
        permissions: '0644'
      - path: /tmp/named.conf.local
        content: |
          zone "homelab.local" IN {
              type master;
              file "/etc/bind/db.homelab.local";
              allow-update { none; };
          };
          zone "100.168.192.in-addr.arpa" IN {
              type master;
              file "/etc/bind/db.192.168.100";
              allow-update { none; };
          };
        permissions: '0644'
      - path: /tmp/db.homelab.local
        content: |
          $TTL 86400
          @   IN  SOA  ns1.homelab.local. admin.homelab.local. (
                    2025042202 ; Serial
                    3600       ; Refresh
                    1800       ; Retry
                    604800     ; Expire
                    86400      ; Minimum TTL
          )
          @       IN  NS   ns1.homelab.local.
          ns1     IN  A    192.168.100.3
          dns     IN  A    192.168.100.3
          bind9-dns-server IN A 192.168.100.3
          k8s-control-plane-0 IN A ${format("192.168.100.%d", var.k8s_control_plane_ip_start)}
          %{~ for i in range(1, var.proxmox_number_of_vm_k8s_control_plane) ~}
          k8s-control-plane-${i} IN A ${format("192.168.100.%d", var.k8s_control_plane_ip_start + i)}
          %{~ endfor ~}
          %{~ for i in range(var.proxmox_number_of_vm_k8s_worker_node) ~}
          k8s-worker-node-${i} IN A ${format("192.168.100.%d", var.k8s_worker_ip_start + i)}
          %{~ endfor ~}
        permissions: '0644'
      - path: /tmp/db.192.168.100
        content: |
          $TTL 86400
          @   IN  SOA  ns1.homelab.local. admin.homelab.local. (
                    2025042202 ; Serial
                    3600       ; Refresh
                    1800       ; Retry
                    604800     ; Expire
                    86400      ; Minimum TTL
          )
          @       IN  NS   ns1.homelab.local.
          3       IN  PTR  ns1.homelab.local.
          3       IN  PTR  bind9-dns-server.homelab.local.
          ${var.k8s_control_plane_ip_start} IN PTR k8s-control-plane-0.homelab.local.
          %{~ for i in range(1, var.proxmox_number_of_vm_k8s_control_plane) ~}
          ${var.k8s_control_plane_ip_start + i} IN PTR k8s-control-plane-${i}.homelab.local.
          %{~ endfor ~}
          %{~ for i in range(var.proxmox_number_of_vm_k8s_worker_node) ~}
          ${var.k8s_worker_ip_start + i} IN PTR k8s-worker-node-${i}.homelab.local.
          %{~ endfor ~}
        permissions: '0644'
      - path: /etc/resolv.conf
        content: |
          nameserver 127.0.0.1
          nameserver 8.8.8.8
          search homelab.local
        permissions: '0644'
    runcmd:
      - echo "Starting DNS server setup" > /tmp/dns-config.log
      - systemctl disable systemd-resolved >> /tmp/dns-config.log 2>&1
      - systemctl stop systemd-resolved >> /tmp/dns-config.log 2>&1
      - apt update >> /tmp/dns-config.log 2>&1 || { echo "apt update failed" >> /tmp/dns-config.log; exit 1; }
      - DEBIAN_FRONTEND=noninteractive apt install -y -o Dpkg::Options::="--force-confnew" bind9 bind9utils qemu-guest-agent >> /tmp/dns-config.log 2>&1 || { echo "apt install failed" >> /tmp/dns-config.log; exit 1; }
      - mv /tmp/named.conf.options /etc/bind/named.conf.options >> /tmp/dns-config.log 2>&1
      - mv /tmp/named.conf.local /etc/bind/named.conf.local >> /tmp/dns-config.log 2>&1
      - mv /tmp/db.homelab.local /etc/bind/db.homelab.local >> /tmp/dns-config.log 2>&1
      - mv /tmp/db.192.168.100 /etc/bind/db.192.168.100 >> /tmp/dns-config.log 2>&1
      - chown bind:bind /etc/bind /etc/bind/* >> /tmp/dns-config.log 2>&1
      - named-checkconf /etc/bind/named.conf.local >> /tmp/dns-config.log 2>&1 || { echo "named.conf.local check failed" >> /tmp/dns-config.log; exit 1; }
      - named-checkzone homelab.local /etc/bind/db.homelab.local >> /tmp/dns-config.log 2>&1 || { echo "homelab.local zone check failed" >> /tmp/dns-config.log; exit 1; }
      - named-checkzone 100.168.192.in-addr.arpa /etc/bind/db.192.168.100 >> /tmp/dns-config.log 2>&1 || { echo "reverse zone check failed" >> /tmp/dns-config.log; exit 1; }
      - systemctl enable named >> /tmp/dns-config.log 2>&1
      - systemctl restart named >> /tmp/dns-config.log 2>&1 || { echo "named start failed" >> /tmp/dns-config.log; exit 1; }
      - sleep 5
      - systemctl status named >> /tmp/dns-config.log 2>&1 || { echo "named service not running" >> /tmp/dns-config.log; exit 1; }
      - systemctl enable qemu-guest-agent >> /tmp/dns-config.log 2>&1
      - systemctl start qemu-guest-agent >> /tmp/dns-config.log 2>&1
      - timedatectl set-timezone America/Toronto >> /tmp/dns-config.log 2>&1
      - nslookup ns1.homelab.local 127.0.0.1 >> /tmp/dns-config.log 2>&1 || { echo "DNS resolution failed for ns1.homelab.local" >> /tmp/dns-config.log; exit 1; }
      - nslookup dns.homelab.local 127.0.0.1 >> /tmp/dns-config.log 2>&1 || { echo "DNS resolution failed for dns.homelab.local" >> /tmp/dns-config.log; exit 1; }
      - nslookup bind9-dns-server.homelab.local 127.0.0.1 >> /tmp/dns-config.log 2>&1 || { echo "DNS resolution failed for bind9-dns-server.homelab.local" >> /tmp/dns-config.log; exit 1; }
      - echo "DNS server setup complete" > /tmp/dns-config.done
    EOF

    file_name = "dns-cloud-config.yaml"
  }
}

# DNS Server VM
resource "proxmox_virtual_environment_vm" "dns_server" {
  name        = "dns-server"
  node_name   = var.proxmox_node_name
  stop_on_destroy = true

  agent {
    enabled = true
  }

  initialization {
    user_data_file_id = proxmox_virtual_environment_file.dns_cloud_config.id

    ip_config {
      ipv4 {
        address = "192.168.100.3/24"
        gateway = "192.168.100.1"
      }
    }
  }

  disk {
    datastore_id = var.proxmox_datastore_name
    file_id      = proxmox_virtual_environment_download_file.ubuntu_cloud_image.id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = 20
  }

  cpu {
    architecture = "x86_64"
    cores = 1
    type = "host"
  }

  memory {
    dedicated = 1024
  }

  network_device {
    bridge = "vmbr0"
  }

  depends_on = [proxmox_virtual_environment_file.dns_cloud_config]
}

# k8s kubeadm cluster Cloud-Init Configuration
resource "proxmox_virtual_environment_file" "k8s_cloud_config" {
  content_type = "snippets"
  datastore_id = var.proxmox_datastore_name
  node_name    = var.proxmox_node_name

  source_raw {
    data = <<-EOF
    #cloud-config
    disk_setup:
      ephemeral0:
        table_type: mbr
        layout: auto
      /dev/vdb:
        table_type: mbr
        layout: true
        overwrite: false
    fs_setup:
      - label: ephemeral0
        filesystem: ext4
        device: /dev/vdb1
    mounts:
      - [ vdb, /var/openebs/local, ext4, "defaults,nofail", 0, 0 ]
    users:
      - default
      - name: ${var.proxmox_vm_user}
        groups:
          - sudo
        shell: /bin/bash
        ssh_authorized_keys:
          - ${trimspace(data.local_file.ssh_public_key.content)}
        sudo: ALL=(ALL) NOPASSWD:ALL
    write_files:
      - path: /etc/resolv.conf
        content: |
          nameserver 192.168.100.3
          search homelab.local
        permissions: '0644'
      - path: /root/kubeadm-config.yaml
        content: |
          apiVersion: kubeadm.k8s.io/v1beta3
          kind: InitConfiguration
          nodeRegistration:
            name: ${var.proxmox_vm_name_k8s_control_plane}0
          ---
          apiVersion: kubeadm.k8s.io/v1beta3
          kind: ClusterConfiguration
          kubernetesVersion: v1.29.8
          controlPlaneEndpoint: ${format("192.168.100.%d", var.k8s_control_plane_ip_start)}:6443
          networking:
            podSubnet: 10.45.0.0/16
        permissions: '0600'
      - path: /root/calico-custom-resources.yaml
        content: |
          apiVersion: operator.tigera.io/v1
          kind: Installation
          metadata:
            name: default
          spec:
            calicoNetwork:
              ipPools:
              - name: default-ipv4-ippool
                blockSize: 26
                cidr: 10.45.0.0/16
                encapsulation: VXLANCrossSubnet
                natOutgoing: Enabled
                nodeSelector: all()
          ---
          apiVersion: operator.tigera.io/v1
          kind: APIServer
          metadata:
            name: default
          spec: {}
        permissions: '0600'
    runcmd:
      # Set hostname based on VM IP
      - |
        echo "Starting hostname setup" > /tmp/cloud-init.log
        IP_ADDR=$(ip -4 addr show | grep inet | grep -v 127.0.0.1 | head -1 | awk '{print $2}' | cut -d'/' -f1)
        HOSTNAME=""
        %{~ for i in range(var.proxmox_number_of_vm_k8s_control_plane) ~}
        if [ "${format("192.168.100.%d", var.k8s_control_plane_ip_start + i)}" = "$IP_ADDR" ]; then
          HOSTNAME="${var.proxmox_vm_name_k8s_control_plane}${i}"
        fi
        %{~ endfor ~}
        %{~ for i in range(var.proxmox_number_of_vm_k8s_worker_node) ~}
        if [ "${format("192.168.100.%d", var.k8s_worker_ip_start + i)}" = "$IP_ADDR" ]; then
          HOSTNAME="${var.proxmox_vm_name_k8s_worker_node}${i}"
        fi
        %{~ endfor ~}
        if [ -n "$HOSTNAME" ]; then
          echo "Setting hostname to $HOSTNAME" >> /tmp/cloud-init.log
          hostnamectl set-hostname "$HOSTNAME"
          echo "127.0.0.1 $HOSTNAME" >> /etc/hosts
          echo "Hostname set successfully" >> /tmp/cloud-init.log
        else
          echo "Failed to set hostname: No matching IP for $IP_ADDR" >> /tmp/cloud-init.log
          exit 1
        fi
      # Install prerequisites
      - |
        echo "Installing prerequisites" >> /tmp/cloud-init.log
        apt update >> /tmp/cloud-init.log 2>&1 || { echo "apt update failed" >> /tmp/cloud-init.log; exit 1; }
        apt install -y apt-transport-https ca-certificates curl gnupg net-tools jq python3 qemu-guest-agent >> /tmp/cloud-init.log 2>&1 || { echo "apt install failed" >> /tmp/cloud-init.log; exit 1; }
        systemctl enable qemu-guest-agent >> /tmp/cloud-init.log 2>&1
        systemctl start qemu-guest-agent >> /tmp/cloud-init.log 2>&1
        timedatectl set-timezone America/Sao_Paulo >> /tmp/cloud-init.log 2>&1
      # Configure kernel modules
      - |
        echo "Configuring kernel modules" >> /tmp/cloud-init.log
        cat <<EOM | tee /etc/modules-load.d/k8s.conf
        overlay
        br_netfilter
        EOM
        modprobe overlay >> /tmp/cloud-init.log 2>&1 || { echo "modprobe overlay failed" >> /tmp/cloud-init.log; exit 1; }
        modprobe br_netfilter >> /tmp/cloud-init.log 2>&1 || { echo "modprobe br_netfilter failed" >> /tmp/cloud-init.log; exit 1; }
      # Configure sysctl settings
      - |
        echo "Configuring sysctl settings" >> /tmp/cloud-init.log
        cat <<EOM | tee /etc/sysctl.d/k8s.conf
        net.bridge.bridge-nf-call-iptables  = 1
        net.bridge.bridge-nf-call-ip6tables = 1
        net.ipv4.ip_forward                 = 1
        EOM
        sysctl --system >> /tmp/cloud-init.log 2>&1 || { echo "sysctl failed" >> /tmp/cloud-init.log; exit 1; }
      # Install containerd
      - |
        echo "Installing containerd" >> /tmp/cloud-init.log
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg >> /tmp/cloud-init.log 2>&1 || { echo "containerd key setup failed" >> /tmp/cloud-init.log; exit 1; }
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu jammy stable" > /etc/apt/sources.list.d/docker.list
        apt update >> /tmp/cloud-init.log 2>&1 || { echo "apt update for containerd failed" >> /tmp/cloud-init.log; exit 1; }
        apt install -y containerd.io >> /tmp/cloud-init.log 2>&1 || { echo "containerd install failed" >> /tmp/cloud-init.log; exit 1; }
        containerd config default | tee /etc/containerd/config.toml >> /tmp/cloud-init.log 2>&1
        sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml >> /tmp/cloud-init.log 2>&1
        systemctl restart containerd >> /tmp/cloud-init.log 2>&1 || { echo "containerd restart failed" >> /tmp/cloud-init.log; exit 1; }
        systemctl enable containerd >> /tmp/cloud-init.log 2>&1
      # Install Kubernetes components
      - |
        echo "Installing Kubernetes components" >> /tmp/cloud-init.log
        curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | gpg --dearmor -o /usr/share/keyrings/kubernetes-apt-keyring.gpg >> /tmp/cloud-init.log 2>&1 || { echo "Kubernetes key setup failed" >> /tmp/cloud-init.log; exit 1; }
        echo "deb [signed-by=/usr/share/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" > /etc/apt/sources.list.d/kubernetes.list
        apt update >> /tmp/cloud-init.log 2>&1 || { echo "apt update for Kubernetes failed" >> /tmp/cloud-init.log; exit 1; }
        apt install -y kubelet=1.29.8-1.1 kubeadm=1.29.8-1.1 kubectl=1.29.8-1.1 >> /tmp/cloud-init.log 2>&1 || { echo "Kubernetes install failed" >> /tmp/cloud-init.log; exit 1; }
        apt-mark hold kubelet kubeadm kubectl >> /tmp/cloud-init.log 2>&1
        systemctl enable --now kubelet >> /tmp/cloud-init.log 2>&1
      # Test DNS resolution
      - |
        echo "Testing DNS resolution" >> /tmp/cloud-init.log
        ping -c 1 192.168.100.3 >> /tmp/cloud-init.log 2>&1 || { echo "DNS server unreachable" >> /tmp/cloud-init.log; exit 1; }
        nslookup homelab.local 192.168.100.3 >> /tmp/cloud-init.log 2>&1 || { echo "DNS resolution failed" >> /tmp/cloud-init.log; exit 1; }
      # Initialize cluster on first control plane node
      - |
        if [ "${var.proxmox_vm_name_k8s_control_plane}0" = "$(hostname)" ]; then
          echo "Initializing control plane" >> /tmp/cloud-init.log
          kubeadm init --config=/root/kubeadm-config.yaml --upload-certs >> /tmp/kubeadm-init.log 2>&1
          if [ $? -ne 0 ]; then
            echo "kubeadm init failed" >> /tmp/cloud-init.log
            exit 1
          fi
          mkdir -p /home/${var.proxmox_vm_user}/.kube >> /tmp/cloud-init.log 2>&1
          cp /etc/kubernetes/admin.conf /home/${var.proxmox_vm_user}/.kube/config >> /tmp/cloud-init.log 2>&1
          chown ${var.proxmox_vm_user}:${var.proxmox_vm_user} /home/${var.proxmox_vm_user}/.kube/config >> /tmp/cloud-init.log 2>&1
          kubeadm token create --print-join-command > /tmp/k8s-join-token 2>> /tmp/cloud-init.log
          kubeadm init phase upload-certs --upload-certs | grep -o '[0-9a-f]\{64\}' > /tmp/k8s-cert-key 2>> /tmp/cloud-init.log
          python3 -m http.server 8000 --directory /tmp >> /tmp/http-server.log 2>&1 &
          export KUBECONFIG=/home/${var.proxmox_vm_user}/.kube/config
          kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.1/manifests/tigera-operator.yaml >> /tmp/cloud-init.log 2>&1
          kubectl create -f /root/calico-custom-resources.yaml >> /tmp/cloud-init.log 2>&1
        fi
      # Join additional control plane nodes
      - |
        %{~ for i in range(1, var.proxmox_number_of_vm_k8s_control_plane) ~}
        if [ "${var.proxmox_vm_name_k8s_control_plane}${i}" = "$(hostname)" ]; then
          echo "Joining control plane node ${var.proxmox_vm_name_k8s_control_plane}${i}" >> /tmp/cloud-init.log
          for attempt in {1..3}; do
            JOIN_CMD=$(curl -s http://${format("192.168.100.%d", var.k8s_control_plane_ip_start)}:8000/k8s-join-token)
            if [ -n "$JOIN_CMD" ]; then
              break
            fi
            echo "Retry $attempt: Failed to fetch join token" >> /tmp/cloud-init.log
            sleep 30
          done
          if [ -z "$JOIN_CMD" ]; then
            echo "Failed to fetch join token after 3 attempts" >> /tmp/cloud-init.log
            exit 1
          fi
          CERT_KEY=$(curl -s http://${format("192.168.100.%d", var.k8s_control_plane_ip_start)}:8000/k8s-cert-key)
          sh -c "$JOIN_CMD --control-plane --certificate-key $CERT_KEY" >> /tmp/cloud-init.log 2>&1
          if [ $? -ne 0 ]; then
            echo "kubeadm join failed for control plane" >> /tmp/cloud-init.log
            exit 1
          fi
        fi
        %{~ endfor ~}
      # Join worker node
      - |
        %{~ for i in range(var.proxmox_number_of_vm_k8s_worker_node) ~}
        if [ "${var.proxmox_vm_name_k8s_worker_node}${i}" = "$(hostname)" ]; then
          echo "Joining worker node ${var.proxmox_vm_name_k8s_worker_node}${i}" >> /tmp/cloud-init.log
          for attempt in {1..3}; do
            JOIN_CMD=$(curl -s http://${format("192.168.100.%d", var.k8s_control_plane_ip_start)}:8000/k8s-join-token)
            if [ -n "$JOIN_CMD" ]; then
              break
            fi
            echo "Retry $attempt: Failed to fetch join token" >> /tmp/cloud-init.log
            sleep 30
          done
          if [ -z "$JOIN_CMD" ]; then
            echo "Failed to fetch join token after 3 attempts" >> /tmp/cloud-init.log
            exit 1
          fi
          sh -c "$JOIN_CMD" >> /tmp/cloud-init.log 2>&1
          if [ $? -ne 0 ]; then
            echo "kubeadm join failed for worker node" >> /tmp/cloud-init.log
            exit 1
          fi
        fi
        %{~ endfor ~}
      # Mark setup complete
      - echo "Kubernetes setup complete" > /tmp/cloud-config.done
    EOF

    file_name = "cloud-config.yaml"
  }

  depends_on = [proxmox_virtual_environment_vm.dns_server]

}

# Existing Kubernetes Control Plane VMs
resource "proxmox_virtual_environment_vm" "k8s-control-plane" {
    count      = var.proxmox_number_of_vm_k8s_control_plane
    name       = format("%s%s", var.proxmox_vm_name_k8s_control_plane, count.index)
    node_name  = var.proxmox_node_name
    stop_on_destroy = true

    agent {
      enabled = true
    }

    initialization {
      user_data_file_id = proxmox_virtual_environment_file.k8s_cloud_config.id

      ip_config {
        ipv4 {
          address = format("192.168.100.%d/24", count.index + var.k8s_control_plane_ip_start)
          gateway = "192.168.100.1"
        }
      }
    }

    disk {
      datastore_id = var.proxmox_datastore_name
      file_id      = proxmox_virtual_environment_download_file.ubuntu_cloud_image.id
      interface    = "virtio0"
      iothread     = true
      discard      = "on"
      size         = 40
    }

    cpu {
      architecture = "x86_64"
      cores = 2
      type = "host"
    }

    memory {
      dedicated = 4096
    }

    network_device {
      bridge = "vmbr0"
    }

    depends_on = [proxmox_virtual_environment_file.k8s_cloud_config, proxmox_virtual_environment_vm.dns_server]
}

# Existing Kubernetes Worker Nodes
resource "proxmox_virtual_environment_vm" "k8s-worker-node" {
    count      = var.proxmox_number_of_vm_k8s_worker_node
    name       = format("%s%s", var.proxmox_vm_name_k8s_worker_node, count.index)
    node_name  = var.proxmox_node_name
    stop_on_destroy = true

    agent {
      enabled = true
    }

    initialization {
      user_data_file_id = proxmox_virtual_environment_file.k8s_cloud_config.id

      ip_config {
        ipv4 {
          address = format("192.168.100.%d/24", count.index + var.k8s_worker_ip_start)
          gateway = "192.168.100.1"
        }
      }
    }

    disk {
      datastore_id = var.proxmox_datastore_name
      file_id      = proxmox_virtual_environment_download_file.ubuntu_cloud_image.id
      interface    = "virtio0"
      iothread     = true
      discard      = "on"
      size         = 30
    }

    disk {
      datastore_id = var.proxmox_datastore_name
      interface    = "virtio1"
      iothread     = true
      discard      = "on"
      size         = 100
    }

    cpu {
      architecture = "x86_64"
      cores = 4
      type = "host"
    }

    memory {
      dedicated = 6144
    }

    network_device {
      bridge = "vmbr0"
    }

    depends_on = [proxmox_virtual_environment_vm.k8s-control-plane]
}

# Ubuntu Cloud Image
resource "proxmox_virtual_environment_download_file" "ubuntu_cloud_image" {
    content_type = "iso"
    datastore_id = var.proxmox_datastore_name
    node_name    = var.proxmox_node_name
    upload_timeout = 2500

    url = "https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img"
}

# SSH Public Key
data "local_file" "ssh_public_key" {
    filename = "./id_rsa.pub"
}

#TODO: Prepare one node to be the "IA node"
#TODO: https://hub.docker.com/r/ollama/ollama