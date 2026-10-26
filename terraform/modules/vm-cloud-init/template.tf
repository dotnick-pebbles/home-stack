resource "proxmox_virtual_environment_file" "user_data_cloud_config" {
  content_type = "snippets"
  datastore_id = var.snippet_datastore_id
  node_name    = var.node_name

  source_raw {
    data = templatefile("${path.module}/cloud-init.tftpl", {
      timezone  = var.timezone
      host_name = var.vm_name
      users     = var.users
    })

    file_name = "vm-${var.vm_name}-cloud-config.yaml"
  }
}

resource "proxmox_virtual_environment_vm" "cloud_vm" {
  name      = var.vm_name
  node_name = var.node_name
  vm_id     = var.vm_id
  machine   = var.vm_machine
  pool_id   = var.pool_id

  initialization {
    datastore_id = var.cloud_init_disk_datastore_id

    ip_config {
      ipv4 {
        address = var.ipv4_address
        gateway = var.gateway
      }
    }

    dns {
      servers = var.dns_servers
    }

    user_data_file_id = proxmox_virtual_environment_file.user_data_cloud_config.id
  }

  # Requires VM.Config.Options on path /vms/<vimid>
  # tags = [var.environment, "terraform", "debian"]

  on_boot = true

  agent {
    enabled = true
  }

  cpu {
    cores   = var.vm_cpu_cores
    sockets = 1
    type    = var.vm_cpu_type
  }

  memory {
    dedicated = var.memory_mib
  }

  disk {
    datastore_id = var.disk_datastore_id
    import_from  = var.cloud_image_id
    interface    = "scsi0"
    discard      = "on"
    size         = var.disksize_gb
  }

  network_device {
    bridge = "vmbr0"
  }
}
