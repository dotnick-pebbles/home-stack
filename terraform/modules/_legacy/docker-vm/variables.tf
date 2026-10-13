variable "proxmox_ve_endpoint" {}
variable "proxmox_ve_api_token" {
  sensitive = true
}
variable "proxmox_ve_ssh_username" {
  sensitive = true
}
variable "proxmox_ve_ssh_password" {
  sensitive = true
}

variable "node_name" {
  type = string
}

variable "vm_name" {}
variable "vm_id" {}

variable "memory_mib" {
  type    = number
  default = 2048
}

variable "disksize_gb" {
  type    = number
  default = 8
}

variable "ipv4_address" {}
variable "environment" {}
