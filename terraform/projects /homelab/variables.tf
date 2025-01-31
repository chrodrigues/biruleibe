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
  sensitive = true
}

variable "proxmox_vm_user" {
  description = "linux username"
  type = string
}

variable "proxmox_vm_password" {
  description = "linux user password"
  type = string
  sensitive = true
}