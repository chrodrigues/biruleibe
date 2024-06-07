variable "proxmox_endpoint" {
  description = "proxmox server address"
  type = string
}

variable "proxmox_user_name" {
  description = "proxmox api token id"
  type = string
}

variable "proxmox_user_password" {
  description = "proxmox api token secret"
  type = string
}

variable "proxmox_node_name" {
  description = "proxmox server name"
  type = string
  default = "homelab"
}

variable "proxmox_vm_name" {
  description = "proxmox server name"
  type = string
  default = "k8s-node-"
}

variable "proxmox_number_of_vm" {
  description = "number of k8s nodes"
  type = string
  default = "3"
}

variable "proxmox_vm_ip_address_start" {
  description = "vm ip address"
  type = string
  default = "50"
}

variable "proxmox_datastore_id" {
  description = "virtual machines datastore"
  type = string
  default = "storage-kingston1TB"
}