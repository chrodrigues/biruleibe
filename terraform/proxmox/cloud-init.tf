data "local_file" "ssh_public_key" {
  filename = "./id_rsa.pub"
}

  resource "proxmox_virtual_environment_vm" "k8s-node" {
    count      = var.proxmox_number_of_vm
    name      = format("%s%s",var.proxmox_vm_name,count.index)
    node_name = var.proxmox_node_name



  initialization {

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