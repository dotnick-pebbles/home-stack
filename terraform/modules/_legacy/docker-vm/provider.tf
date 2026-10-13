terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.113.1"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_ve_endpoint
  api_token = var.proxmox_ve_api_token

  insecure = true
  ssh {
    agent    = false
    username = var.proxmox_ve_ssh_username
    password = var.proxmox_ve_ssh_password
  }
}
