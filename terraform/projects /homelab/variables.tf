variable "proxmox_endpoint" {
  description = "proxmox server address"
  type        = string
}

variable "proxmox_user_name" {
  description = "proxmox api token id"
  type        = string
}

variable "proxmox_user_password" {
  description = "proxmox api token secret"
  type        = string
  sensitive   = true
}

variable "proxmox_vm_user" {
  description = "linux username"
  type        = string
}

variable "proxmox_vm_password" {
  description = "linux user password"
  type        = string
  sensitive   = true
}

variable "proxmox_number_of_vm_k8s_worker_node" {
  description = "number of k8s nodes"
  type        = string
  default     = "3"
}

variable "proxmox_number_of_vm_k8s_control_plane" {
  description = "number of k8s nodes"
  type        = string
  default     = "1"
}

variable "k8s_control_plane_ip_start" {
  description = "vm ip address"
  type        = string
  default     = "50"
}

variable "k8s_worker_ip_start" {
  description = "vm ip address"
  type        = string
  default     = "60"
}

variable "proxmox_snippets_datastore_name" {
  description = "virtual machines datastore"
  type        = string
  default     = "local"
}

variable "proxmox_vmdisk_datastore_name" {
  description = "virtual machines disks datastore"
  type        = string
  default     = "local-lvm"
}

variable "proxmox_node_name" {
  description = "proxmox server name"
  type        = string
  default     = "proxmox"
}

#variable "metrics_server_version" {
#    type = string
#    description = "Versão do helm chart do metrics server"
#}

variable "prometheus_metrics_server_replicas" {
  type        = string
  description = "Número de replicas do metrics server"
  default     = 1
}

variable "prometheus_retention" {
  type        = string
  description = "Tempo de retenção das métricas"
  default     = "7"
}

variable "prometheus_storageclass_name" {
  type        = string
  description = "Tamanho do disco para o Prometheus"
  default     = "openebs"
}

variable "prometheus_disk_size" {
  type        = string
  description = "Tamanho do disco para o Prometheus"
  default     = 50
}


variable "grafana_password_admin" {
  type        = string
  description = "Senha usuário admin grafana dashboards"
}

variable "grafana_disk_size" {
  type        = string
  description = "Tamanho do disco para o Grafana"
  default     = 10
}

variable "grafana_storageclass_name" {
  type        = string
  description = "Tamanho do disco para o Grafana"
  default     = "openebs"
}