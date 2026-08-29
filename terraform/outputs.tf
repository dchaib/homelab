output "vms" {
  description = "Deployed virtual machines information."

  value = {
    ha = {
      id   = proxmox_virtual_environment_vm.ha_vm.vm_id
      name = proxmox_virtual_environment_vm.ha_vm.name
      ipv4 = try(
        one([
          for ip in flatten(proxmox_virtual_environment_vm.ha_vm.ipv4_addresses) :
          ip if startswith(ip, var.lan_ipv4_prefix)
        ]),
        null
      )
    }

    services = {
      id   = proxmox_virtual_environment_vm.services_vm.vm_id
      name = proxmox_virtual_environment_vm.services_vm.name
      ipv4 = try(
        one([
          for ip in flatten(proxmox_virtual_environment_vm.services_vm.ipv4_addresses) :
          ip if startswith(ip, var.lan_ipv4_prefix)
        ]),
        null
      )
    }
  }
}
