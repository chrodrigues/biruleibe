module "proxmox"  {
  source = "../../modules/proxmox"
  proxmox_endpoint = var.proxmox_endpoint
  proxmox_vm_password = var.proxmox_vm_password
  proxmox_user_name = var.proxmox_user_name
  proxmox_user_password = var.proxmox_user_password
  proxmox_vm_user = var.proxmox_vm_user
}