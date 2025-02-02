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

variable "proxmox_node_name" {
  description = "proxmox server name"
  type = string
}

variable "proxmox_vm_name_k8s_worker_node" {
  description = "k8s worker node name"
  type = string
  default = "k8s-worker-"
}

variable "proxmox_vm_name_k8s_control_plane" {
  description = "k8s control plane name"
  type = string
  default = "k8s-control-plane-"
}

variable "proxmox_number_of_vm_k8s_worker_node" {
  description = "number of k8s nodes"
  type = string
}

variable "proxmox_number_of_vm_k8s_control_plane" {
  description = "number of k8s nodes"
  type = string
}

variable "k8s_control_plane_ip_start" {
  description = "vm ip address"
  type = string
}

variable "k8s_worker_ip_start" {
  description = "vm ip address"
  type = string
}

variable "proxmox_datastore_name" {
  description = "virtual machines datastore"
  type = string
  default = "local"
}