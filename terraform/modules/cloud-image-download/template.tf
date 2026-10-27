resource "proxmox_download_file" "cloud_images" {
  for_each     = tomap({ for o in var.cloud_images : o.file_name => o })
  node_name    = var.node_name
  datastore_id = each.value.datastore_id != null ? each.value.datastore_id : var.default_datastore_id
  content_type = each.value.content_type
  url          = each.value.url
  file_name    = each.value.file_name
}
