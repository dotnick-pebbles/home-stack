output "cloud_image_ids" {
  value = try(one(module.download_cloud_images).cloud_image_ids, null)
}

output "json_config" {
  value = local.env_json_config
}
