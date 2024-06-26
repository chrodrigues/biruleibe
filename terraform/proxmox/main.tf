resource "proxmox_virtual_environment_file" "cloud_config" {
    content_type = "snippets"
    datastore_id = var.proxmox_datastore_id
    node_name    = var.proxmox_node_name

    source_raw {
      data = <<-EOF
      #cloud-config
      users:
        - default
        - name: crodrigues
          groups:
            - sudo
          shell: /bin/bash
          ssh_authorized_keys:
            - ${trimspace(data.local_file.ssh_public_key.content)}
          sudo: ALL=(ALL) NOPASSWD:ALL
      runcmd:
          -  echo "PROXMOX_USERNAME=${var.proxmox_user_name}" > /tmp/credential.env
          -  echo "PROXMOX_PASSWORD=${var.proxmox_user_password}" >> /tmp/credential.env
          -  echo "PROXMOX_HOST=${var.proxmox_endpoint}" >> /tmp/credential.env
          - apt update
          - apt install -y qemu-guest-agent net-tools jq
          - timedatectl set-timezone America/Toronto
          - systemctl enable qemu-guest-agent
          - systemctl start qemu-guest-agent
          - modprobe br_netfilter
          - wget https://raw.githubusercontent.com/chrodrigues/biruleibe/main/terraform/proxmox/kubeadm_init.sh https://raw.githubusercontent.com/chrodrigues/biruleibe/main/terraform/proxmox/set_hostname.sh
          - chmod +x /kubeadm_init.sh /set_hostname.sh
          - /bin/bash /kubeadm_init.sh
          - /bin/bash /set_hostname.sh
          - echo "done" > /tmp/cloud-config.done
      EOF

      file_name = "cloud-config.yaml"
    }
  }

resource "proxmox_virtual_environment_vm" "k8s-node" {
    count      = var.proxmox_number_of_vm
    name      = format("%s%s",var.proxmox_vm_name,count.index)
    node_name = var.proxmox_node_name

    agent {
      enabled = true
    }

#provisioner "remote-exec" {
#  command = <<EOF
#    export PROXMOX_USERNAME=${var.proxmox_user_name}
#    export PROXMOX_PASSWORD=${var.proxmox_user_password}
#    export PROXMOX_HOST=${var.proxmox_endpoint}
#    wget -q -O /var/lib/cloud/scripts/per-once https://raw.githubusercontent.com/chrodrigues/biruleibe/main/terraform/proxmox/set_hostname.sh
#    chmod +x /var/lib/cloud/scripts/per-once/set_hostname.sh
#  EOF
#}

  initialization {
    user_data_file_id = proxmox_virtual_environment_file.cloud_config.id

    ip_config {
      ipv4 {
        address = format("192.168.100.%d/24", count.index + var.proxmox_vm_ip_address_start)
        gateway = "192.168.100.1"
      }
    }

    user_account {
      username = "crodrigues"
      keys     = [trimspace(data.local_file.ssh_public_key.content)]
    }
  }

  disk {
    datastore_id = var.proxmox_datastore_id
    file_id      = proxmox_virtual_environment_download_file.ubuntu_cloud_image.id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = 40
  }

  network_device {
    bridge = "vmbr0"
  }
}

resource "proxmox_virtual_environment_download_file" "ubuntu_cloud_image" {
  content_type = "iso"
  datastore_id = var.proxmox_datastore_id
  node_name    = var.proxmox_node_name
  upload_timeout  = 2500

  url = "https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img"
}

data "local_file" "ssh_public_key" {
  filename = "./id_rsa.pub"
}