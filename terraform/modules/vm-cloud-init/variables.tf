variable "node_name" {
  type = string
}
variable "pool_id" {
  type = string
}
variable "disk_datastore_id" {
  type = string
}
variable "cloud_init_disk_datastore_id" {
  type = string
}
variable "snippet_datastore_id" {
  type = string
}
variable "vm_id" {
  type = number
}
variable "vm_name" {
  type = string
}
variable "cloud_image_id" {
  type = string
}
variable "users" {}
variable "vm_machine" {
  type    = string
  default = null
}
variable "vm_cpu_cores" {
  type    = number
  default = 1
}
variable "vm_cpu_type" {
  type    = string
  default = "host"
}
variable "memory_mib" {
  type    = number
  default = 2048
}
variable "disksize_gb" {
  type    = number
  default = 8
}
variable "gateway" {
  type = string
}
variable "ipv4_address" {
  type = string
}
variable "dns_servers" {
  type = list(string)
}
variable "environment" {
  type = string
}
variable "timezone" {
  type    = string
  default = "Europe/Copenhagen"
}
