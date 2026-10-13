
variable "node_name" {
  type = string
}
variable "pool_id" {
  type = string
}
variable "datastore_id" {
  type = string
}
variable "container_id" {
  type = number
}
variable "container_name" {
  type = string
}
variable "template_name" {
  type = string
}
variable "operating_system_type" {
  type = string
}
variable "memory_mib" {
  type    = number
  default = 512
}
variable "memory_swap_mib" {
  type    = number
  default = 512
}
variable "disksize_gb" {
  type    = number
  default = 4
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

variable "authorized_ssh" {
  type = object({
    keys       = optional(list(string), [])
    key_paths  = optional(list(string), [])
    keys_paths = optional(list(string), [])
  })
  default = {}
}
