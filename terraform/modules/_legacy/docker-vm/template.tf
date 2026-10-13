resource "proxmox_virtual_environment_vm" "vm" {
  name      = var.vm_name
  node_name = var.node_name
  vm_id     = var.vm_id

  tags = [var.environment, "terraform", "debian"]

  agent {
    # read 'Qemu guest agent' section, change to true only when ready
    enabled = true
  }

  on_boot = true

  clone {
    vm_id = 9000 # debian-13-base-template
    # vm_id = 9001 # debian-11-cloudinit-template
    full = true
  }

  #   cpu {
  #     cores        = 2
  #     sockets      = 1
  #     architecture = "x86_64"
  #     type         = "host"
  #   }

  memory {
    dedicated = var.memory_mib
  }

  disk {
    size         = var.disksize_gb
    datastore_id = "local-lvm"
    interface    = "scsi0"
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  initialization {
    datastore_id = "local-lvm"
    # interface    = "ide0"

    dns {
      servers = ["192.168.50.1"]
    }

    ip_config {
      ipv4 {
        address = var.ipv4_address
        gateway = "192.168.50.1"
      }
    }

    user_account {
      username = var.vm_name
      keys = [
        trimspace(file("key.pub")),
      ]
    }
  }

  lifecycle {
    ignore_changes = [
      vga,
    ]
  }
}

# output "docker-cloud-dev_ip" {
#   value = proxmox_virtual_environment_vm.docker-cloud-dev.ipv4_addresses[1]
# }
