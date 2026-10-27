variable "node_name" {
  type = string
}
variable "default_datastore_id" {
  type = string
}
variable "cloud_images" {
  type = list(object({
    url          = string
    file_name    = string
    datastore_id = optional(string, null)
    content_type = string
  }))
}
