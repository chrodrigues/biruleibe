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
}

variable "proxmox_vm_name" {
  description = "proxmox server name"
  type = string
}