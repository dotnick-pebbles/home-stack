variable "vars_path" {
  type = string
}
variable "proxmox_ve_api_token" {
  sensitive = true
}
variable "proxmox_ve_ssh_username" {
  sensitive = true
}
variable "proxmox_ve_ssh_password" {
  sensitive = true
}
variable "environment_full_name" {
  type = string
}

locals {
  # Common variables
  common_json_config              = jsondecode(file("${var.vars_path}/common.config.json"))
  proxmox_ve_host_ip              = local.common_json_config.host_settings.proxmox_ve_host_ip
  proxmox_ve_host_port            = local.common_json_config.host_settings.proxmox_ve_host_port
  proxmox_ve_host_name            = local.common_json_config.host_settings.proxmox_ve_host_name
  proxmox_ve_endpoint             = "https://${local.proxmox_ve_host_ip}:${local.proxmox_ve_host_port}/api2/json"
  pool_id                         = try(local.common_json_config.host_settings.pool_id, null)
  datastore_fallback_id           = local.common_json_config.host_settings.storage_name
  disk_datastore_id               = try(local.common_json_config.host_settings.disk_storage_name, local.datastore_fallback_id)
  container_datastore_id          = try(local.common_json_config.host_settings.container_storage_name, local.datastore_fallback_id)
  iso_datastore_id                = try(local.common_json_config.host_settings.iso_storage_name, local.datastore_fallback_id)
  import_datastore_id             = try(local.common_json_config.host_settings.import_storage_name, local.datastore_fallback_id)
  container_template_datastore_id = try(local.common_json_config.host_settings.container_template_storage_name, local.datastore_fallback_id)
  snippet_datastore_id            = try(local.common_json_config.host_settings.snippet_storage_name, local.datastore_fallback_id)
  authorized_ssh_keys_path        = local.common_json_config.build_server.authorized_ssh_keys_path

  cloud_images = local.common_json_config["cloud_images"]

  # Environment specific variables
  env_json_config = jsondecode(file("${var.vars_path}/${var.environment_full_name}.config.json"))
  vm_list         = { for o in try(local.env_json_config["vms"], []) : o.id => o }
  lxc_list        = { for o in try(local.env_json_config["containers"], []) : o.id => o }
  network_config  = var.environment_full_name != "common" ? local.env_json_config["network"] : null
  common_data     = var.environment_full_name != "common" ? one(data.terraform_remote_state.common_data).outputs : null
}
