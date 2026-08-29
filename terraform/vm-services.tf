locals {
  services_vm_cloud_init = templatefile("${path.module}/templates/services-vm-cloud-init.yaml.tftpl", {
    hostname                = var.services_vm.name
    admin_username          = var.vm_user_admin.username
    admin_authorized_keys   = var.vm_user_admin.authorized_keys
    ansible_username        = var.vm_user_ansible.username
    ansible_authorized_keys = var.vm_user_ansible.authorized_keys
  })
}

resource "proxmox_download_file" "debian" {
  content_type       = "import"
  datastore_id       = var.proxmox.file_datastore
  node_name          = var.proxmox.node_name
  url                = var.debian_image.url
  checksum           = var.debian_image.checksum
  checksum_algorithm = "sha512"
  file_name          = basename(var.debian_image.url)
}

resource "proxmox_virtual_environment_file" "services_vm_cloud_init" {
  content_type = "snippets"
  datastore_id = var.proxmox.file_datastore
  node_name    = var.proxmox.node_name

  source_raw {
    data      = local.services_vm_cloud_init
    file_name = "${var.services_vm.name}.cloud-config.yaml"
  }
}

resource "proxmox_virtual_environment_vm" "services_vm" {
  name = var.services_vm.name
  tags = ["terraform", "debian", "services", "ansible", "docker"]

  node_name = var.proxmox.node_name
  vm_id     = var.services_vm.vm_id
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
    cores = var.services_vm.cpu_cores
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = var.services_vm.memory_mb
  }

  efi_disk {
    datastore_id = var.proxmox.vm_datastore
    type         = "4m"
  }

  disk {
    datastore_id = var.proxmox.vm_datastore
    import_from  = proxmox_download_file.debian.id
    interface    = "scsi0"
    size         = var.services_vm.disk_size_gb
    iothread     = true
    discard      = "on"
    ssd          = true
  }

  network_device {
    bridge = var.proxmox.bridge
    model  = "virtio"
  }

  operating_system {
    type = "l26"
  }

  initialization {
    datastore_id = var.proxmox.vm_datastore

    user_data_file_id = proxmox_virtual_environment_file.services_vm_cloud_init.id

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  lifecycle {
    ignore_changes = [
      disk[0].import_from,
    ]
  }
}
