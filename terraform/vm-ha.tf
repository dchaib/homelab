resource "proxmox_download_file" "haos" {
  content_type            = "iso"
  datastore_id            = var.proxmox.file_datastore
  node_name               = var.proxmox.node_name
  url                     = var.haos_image.url
  checksum                = var.haos_image.checksum
  checksum_algorithm      = "sha256"
  decompression_algorithm = "zst"
  file_name               = "${trimsuffix(basename(var.haos_image.url), ".xz")}.img"
  overwrite               = false
}

resource "proxmox_virtual_environment_vm" "ha_vm" {
  name = var.ha_vm.name
  tags = ["terraform", "haos", "ha"]

  node_name = var.proxmox.node_name
  vm_id     = var.ha_vm.vm_id
  started   = true
  on_boot   = true

  bios            = "ovmf"
  machine         = "q35"
  scsi_hardware   = "virtio-scsi-single"
  boot_order      = ["scsi0"]
  stop_on_destroy = true

  agent {
    enabled = true
  }

  cpu {
    cores = var.ha_vm.cpu_cores
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = var.ha_vm.memory_mb
  }

  efi_disk {
    datastore_id = var.proxmox.vm_datastore
    type         = "4m"
  }

  disk {
    datastore_id = var.proxmox.vm_datastore
    file_id      = proxmox_download_file.haos.id
    interface    = "scsi0"
    size         = var.ha_vm.disk_size_gb
    iothread     = true
    discard      = "on"
    ssd          = true
  }

  network_device {
    bridge = var.proxmox.bridge
    model  = "virtio"
  }

  operating_system {
    type = "other"
  }
}
