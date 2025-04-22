module "proxmox" {
  source                                 = "../../modules/proxmox"
  proxmox_endpoint                       = var.proxmox_endpoint
  proxmox_vm_password                    = var.proxmox_vm_password
  proxmox_user_name                      = var.proxmox_user_name
  proxmox_user_password                  = var.proxmox_user_password
  proxmox_vm_user                        = var.proxmox_vm_user
  k8s_control_plane_ip_start             = var.k8s_control_plane_ip_start
  k8s_worker_ip_start                    = var.k8s_worker_ip_start
  proxmox_number_of_vm_k8s_control_plane = var.proxmox_number_of_vm_k8s_control_plane
  proxmox_number_of_vm_k8s_worker_node   = var.proxmox_number_of_vm_k8s_worker_node
  proxmox_node_name                      = var.proxmox_node_name
}

#module "helm" {
#  source                             = "../../modules/helm"
#  grafana_disk_size                  = ""
#  grafana_password_admin             = ""
#  grafana_storageclass_name          = ""
#  prometheus_disk_size               = ""
#  prometheus_metrics_server_replicas = ""
#  prometheus_retention               = ""
#  prometheus_storageclass_name       = ""
#
#  depends_on = [module.proxmox]
#
#}