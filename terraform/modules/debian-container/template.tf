resource "proxmox_virtual_environment_container" "debian_container" {
  description  = "Managed by Terraform"
  node_name    = var.node_name
  vm_id        = var.container_id
  unprivileged = true
  pool_id      = var.pool_id

  initialization {
    hostname = var.container_name

    ip_config {
      ipv4 {
        address = var.ipv4_address
        gateway = var.gateway
      }
    }

    dns {
      servers = var.dns_servers
    }

    user_account {
      keys = concat(
        [for key in var.authorized_ssh.keys : trimspace(key)],
        [for key_path in var.authorized_ssh.key_paths : trimspace(file("${key_path}"))],
        flatten([
          for key_path in var.authorized_ssh.keys_paths : [
            for key_name in fileset(key_path, "*.pub") :
            trimspace(file("${key_path}/${key_name}"))
          ]
        ])
      )
    }
  }
  # Requires VM.Config.Options on path /vms/<vimid>
  # tags = [var.environment, "terraform", "debian"]

  operating_system {
    template_file_id = "${var.datastore_id}:vztmpl/${var.template_name}"
    type             = var.operating_system_type
  }

  features {
    nesting = true
  }

  memory {
    dedicated = var.memory_mib
    swap      = var.memory_swap_mib
  }

  disk {
    size         = var.disksize_gb
    datastore_id = var.datastore_id
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }
}
