output "cloud_image_ids" {
  value = tomap({
    for key, cloud_image in proxmox_download_file.cloud_images : key => cloud_image.id
  })
}
