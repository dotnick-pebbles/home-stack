variable "node_name" {
  type = string
}
variable "datastore_id" {
  type = string
}
variable "cloud_images" {
  type = list(object({
    url          = string
    file_name    = string
    content_type = string
  }))
}
