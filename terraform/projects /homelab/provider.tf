terraform {

  required_version = ">=0.13.0"

  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      version = "0.58.0"
    }
  }
}

provider "proxmox" {

  endpoint = var.proxmox_endpoint
  password = var.proxmox_user_password
  username = var.proxmox_user_name
  insecure = true

}