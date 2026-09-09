locals {
  ha_vm_mac_address = format(
    "02:00:00:00:%02X:%02X",
    floor(var.ha_vm.vm_id / 256) % 256,
    var.ha_vm.vm_id % 256,
  )

  services_vm_mac_address = format(
    "02:00:00:00:%02X:%02X",
    floor(var.services_vm.vm_id / 256) % 256,
    var.services_vm.vm_id % 256,
  )
}

resource "freebox_dhcp_lease" "ha_vm" {
  count = var.ha_vm.ipv4_address == null ? 0 : 1

  mac      = local.ha_vm_mac_address
  ip       = var.ha_vm.ipv4_address
  hostname = "homeassistant" # This hostname is set by the Home Assistant OS installer and cannot be changed.
  comment  = "Managed by Terraform"
}

resource "freebox_dhcp_lease" "services_vm" {
  count = var.services_vm.ipv4_address == null ? 0 : 1

  mac      = local.services_vm_mac_address
  ip       = var.services_vm.ipv4_address
  hostname = var.services_vm.name
  comment  = "Managed by Terraform"
}

resource "freebox_port_forwarding" "services_vm_https" {
  count = var.services_vm.ipv4_address == null ? 0 : 1

  enabled          = true
  ip_protocol      = "tcp"
  source_ip        = "0.0.0.0"
  port_range_start = 443
  port_range_end   = 443
  target_ip        = freebox_dhcp_lease.services_vm[0].ip
  target_port      = 443
  comment          = "HTTPS to ${var.services_vm.name} - Managed by Terraform"
}
