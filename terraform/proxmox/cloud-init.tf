data "local_file" "ssh_public_key" {
  filename = "./id_rsa.pub"
}

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
          - apt update
          - apt install -y qemu-guest-agent net-tools
          - timedatectl set-timezone America/Toronto
          - systemctl enable qemu-guest-agent
          - systemctl start qemu-guest-agent
          - modprobe br_netfilter
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

  url = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
}