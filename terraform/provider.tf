terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.116.0"
    }
  }
}

provider "proxmox" {
  endpoint  = local.proxmox_ve_endpoint
  api_token = var.proxmox_ve_api_token

  insecure = true
  
  # SSH needed for uploading snippets (part of vm-cloud-init).
  # https://bugzilla.proxmox.com/show_bug.cgi?id=2208
  ssh {
    agent    = false
    username = var.proxmox_ve_ssh_username
    password = var.proxmox_ve_ssh_password

    node {
      name    = local.proxmox_ve_host_name
      address = local.proxmox_ve_host_ip
    }
  }
}
