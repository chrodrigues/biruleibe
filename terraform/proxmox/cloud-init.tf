data "local_file" "ssh_public_key" {
  filename = "./id_rsa.pub"
}

  resource "proxmox_virtual_environment_vm" "k8s-node" {
  name      = var.proxmox_vm_name
  node_name = var.proxmox_node_name

  initialization {

    ip_config {
      ipv4 {
        address = "192.168.100.50/24"
        gateway = "192.168.100.1"
      }
    }

    user_account {
      username = "crodrigues"
      keys     = [trimspace(data.local_file.ssh_public_key.content)]
    }
  }

  disk {
    datastore_id = "storage-kingston1TB"
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
  datastore_id = "storage-kingston1TB"
  node_name    = "homelab"

  url = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
}