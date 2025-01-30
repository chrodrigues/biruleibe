resource "proxmox_virtual_environment_file" "cloud_config" {
    content_type = "snippets"
    datastore_id = var.proxmox_datastore_id
    node_name    = var.proxmox_node_name

    source_raw {
      data = <<-EOF
      #cloud-config
      disk_setup:
         ephmeral0:
             table_type: 'mbr'
             layout: 'auto'
         /dev/vdb:
             table_type: 'mbr'
             layout: true
             overwrite: false
      fs_setup:
         - label: ephemeral0
           filesystem: 'ext4'
           device: '/dev/vdb1'
      mounts:
       - [ vdb, /var/openebs/local, "ext4", "defaults,nofail", "0", "0" ]
      users:
        - default
        - name: ${var.proxmox_vm_user}
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
          - wget https://raw.githubusercontent.com/chrodrigues/biruleibe/main/terraform/proxmox/kubeadm_init.sh https://raw.githubusercontent.com/chrodrigues/biruleibe/main/terraform/proxmox/set_hostname.sh
          - chmod +x /kubeadm_init.sh /set_hostname.sh
          - /bin/bash /kubeadm_init.sh
          - /bin/bash /set_hostname.sh
          - echo "done" > /tmp/cloud-config.done
      EOF

      file_name = "cloud-config.yaml"
    }
  }

resource "proxmox_virtual_environment_vm" "k8s-control-plane" {
    count      = var.proxmox_number_of_vm_k8s_control_plane
    name      = format("%s%s",var.proxmox_vm_name_k8s_control_plane,count.index)
    node_name = var.proxmox_node_name
    stop_on_destroy = true

    agent {
      enabled = true
    }

  initialization {
    user_data_file_id = proxmox_virtual_environment_file.cloud_config.id

    ip_config {
      ipv4 {
        address = format("192.168.100.%d/24", count.index + var.k8s_control_plane_ip_start)
        gateway = "192.168.100.1"
      }
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

  cpu {
    architecture = "x86_64"
    cores = 2
  }

  memory {
    dedicated = 4096
  }

  network_device {
    bridge = "vmbr0"
  }

}

resource "proxmox_virtual_environment_vm" "k8s-worker-node" {
  count      = var.proxmox_number_of_vm_k8s_worker_node
  name      = format("%s%s",var.proxmox_vm_name_k8s_worker_node,count.index)
  node_name = var.proxmox_node_name
  stop_on_destroy = true

  agent {
    enabled = true
  }

  initialization {
    user_data_file_id = proxmox_virtual_environment_file.cloud_config.id

    ip_config {
      ipv4 {
        address = format("192.168.100.%d/24", count.index + var.k8s_worker_ip_start)
        gateway = "192.168.100.1"
      }
    }

    #  user_account {
    #    username = "crodrigues"
    #    keys     = [trimspace(data.local_file.ssh_public_key.content)]
    #  }
  }

  disk {
    datastore_id = var.proxmox_datastore_id
    file_id      = proxmox_virtual_environment_download_file.ubuntu_cloud_image.id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = 30
  }

  disk {
    datastore_id = var.proxmox_datastore_id
    interface    = "virtio1"
    iothread     = true
    discard      = "on"
    size         = 100
  }

  cpu {
    architecture = "x86_64"
    cores = 4
  }

  memory {
    dedicated = 6144
  }

  network_device {
    bridge = "vmbr0"
  }

  depends_on = [proxmox_virtual_environment_vm.k8s-control-plane]
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

#TODO: Prepare one node to be the "IA node"
#TODO: https://hub.docker.com/r/ollama/ollama