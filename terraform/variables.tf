variable "proxmox_connection" {
  description = "Proxmox VE connection configuration."
  type = object({
    endpoint     = string
    insecure     = optional(bool, false)
    ssh_username = string
  })
}

variable "proxmox" {
  description = "Proxmox VE environment configuration."
  type = object({
    node_name      = string
    bridge         = optional(string, "vmbr0")
    file_datastore = optional(string, "local")
    vm_datastore   = optional(string, "local-lvm")
  })
}

variable "haos_image" {
  description = "Pinned Home Assistant OS image."
  type = object({
    url      = string
    checksum = string
  })
}

variable "ha_vm" {
  description = "Home Assistant virtual machine configuration."
  type = object({
    vm_id        = optional(number)
    name         = string
    cpu_cores    = optional(number, 2)
    memory_mb    = optional(number, 4096)
    disk_size_gb = optional(number, 32)
  })
}

variable "debian_image" {
  description = "Pinned Debian generic cloud image."
  type = object({
    url      = string
    checksum = string
  })
}

variable "services_vm" {
  description = "Services virtual machine configuration."
  type = object({
    vm_id        = optional(number)
    name         = string
    cpu_cores    = optional(number, 2)
    memory_mb    = optional(number, 4096)
    disk_size_gb = optional(number, 32)
  })
}

variable "vm_user_admin" {
  description = "Admin user account and SSH authorized keys for virtual machines."
  type = object({
    username        = string
    authorized_keys = list(string)
  })
}

variable "vm_user_ansible" {
  description = "Ansible user account and SSH authorized keys for virtual machines."
  type = object({
    username        = string
    authorized_keys = list(string)
  })
}

variable "lan_ipv4_prefix" {
  description = "IPv4 prefix."
  type        = string
  default     = "192.168."
}
