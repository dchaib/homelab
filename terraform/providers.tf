provider "freebox" {}

provider "proxmox" {
  endpoint = var.proxmox_connection.endpoint
  insecure = var.proxmox_connection.insecure

  ssh {
    agent    = true
    username = var.proxmox_connection.ssh_username
  }
}
