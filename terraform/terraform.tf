terraform {
  required_version = ">= 1.12.6"

  required_providers {
    freebox = {
      source  = "NikolaLohinski/freebox"
      version = "2.7.0"
    }

    proxmox = {
      source  = "bpg/proxmox"
      version = "0.112.0"
    }
  }
}
