module "download_cloud_images" {
  count        = var.environment_full_name == "common" ? 1 : 0
  source       = "../../modules/cloud-image-download"
  cloud_images = local.cloud_images
  datastore_id = local.datastore_id
  node_name    = local.proxmox_ve_host_name
}

data "terraform_remote_state" "common_data" {
  count   = var.environment_full_name != "common" ? 1 : 0
  backend = "local"

  config = {
    path = "../common/terraform.tfstate"
  }
}

# Create VMs using JSON configuration
module "docker_vms" {
  source   = "../../modules/vm-cloud-init"
  for_each = local.vm_list

  node_name    = local.proxmox_ve_host_name
  pool_id      = local.pool_id
  datastore_id = local.datastore_id
  environment  = var.environment_full_name
  vm_id        = each.value.id
  vm_machine   = try(each.value.machine, null)
  vm_name      = "${each.value.name}-${var.environment_full_name}"
  users        = each.value.users
  gateway      = local.network_config.gateway
  ipv4_address = "${local.network_config.subnet}.${try(each.value.ip_offset, each.value.id)}/24"
  dns_servers  = local.network_config.dns_servers
  vm_cpu_type  = try(each.value.cpu_type, "host")
  vm_cpu_cores = each.value.cores
  memory_mib   = each.value.memory_mib
  disksize_gb  = each.value.disk_gb

  cloud_image_id = local.common_data.cloud_image_ids[each.value.cloud_image_id_key]
}

# Create containers using JSON configuration
module "docker_containers" {
  source   = "../../modules/debian-container"
  for_each = local.lxc_list

  node_name             = local.proxmox_ve_host_name
  pool_id               = local.pool_id
  datastore_id          = local.datastore_id
  environment           = var.environment_full_name
  container_id          = each.value.id
  container_name        = each.value.name
  template_name         = each.value.template_name
  operating_system_type = try(each.value.operating_system_type, null)
  disksize_gb           = try(each.value.disk_gb, null)
  gateway               = local.network_config.gateway
  ipv4_address          = "${local.network_config.subnet}.${try(each.value.ip_offset, each.value.id)}/24"
  dns_servers           = local.network_config.dns_servers
  authorized_ssh = {
    keys       = try(each.value.ssh.authorized_ssh_keys, [])
    key_paths  = try(each.value.ssh.authorized_ssh_key_paths, [])
    keys_paths = try(each.value.ssh.authorized_ssh_keys_paths, [])
  }
}
