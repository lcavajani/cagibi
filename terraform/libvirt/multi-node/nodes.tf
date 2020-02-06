variable "basename" {
}

variable "image" {
}

variable "node_count" {
}

variable "cloud_init_file" {
}

variable "cloud_init_network_config_file" {
}

variable "storage_pool" {
}

variable "storage_format" {
}

variable "network" {
}

variable "memory" {
}

variable "vcpu" {
}

variable "ssh_privkey" {
}

variable "ssh_user" {
}

# Povider
provider "libvirt" {
  uri = "qemu:///system"
}

###############
### VOLUMES ###
###############

# adapt the build number 
resource "libvirt_volume" "node" {
  name   = "vol-${var.basename}-${count.index}"
  source = var.image
  count  = var.node_count
  pool   = var.storage_pool
  format = var.storage_format
}

##################
### CLOUD-INIT ###
##################

data "template_file" "user_data" {
  template = file(var.cloud_init_file)
}

resource "libvirt_cloudinit_disk" "cloud_init" {
  name           = "cloud_init_${var.basename}.iso"
  pool           = var.storage_pool
  user_data      = data.template_file.user_data.rendered
  network_config = file(var.cloud_init_network_config_file)
}

##########
### VM ###
##########

# Create the machine
resource "libvirt_domain" "node" {
  name   = "${var.basename}-${count.index}"
  memory = var.memory
  vcpu   = var.vcpu
  count  = var.node_count

  cloudinit = libvirt_cloudinit_disk.cloud_init.id

  network_interface {
    network_name   = var.network
    wait_for_lease = true
  }

  # IMPORTANT: this is a known bug on cloud images, since they expect a console
  # we need to pass it
  # https://bugs.launchpad.net/cloud-images/+bug/1573095
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  disk {
    volume_id = element(libvirt_volume.node.*.id, count.index)
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}

resource "null_resource" "node" {
  count = var.node_count

  connection {
    type = "ssh"
    host = element(
        libvirt_domain.node.*.network_interface.0.addresses.0,
        count.index,
    )
    user        = var.ssh_user
    agent       = "false"
    private_key = file(var.ssh_privkey)
  }

  # This ensures the VM is booted and SSH'able
  provisioner "remote-exec" {
    inline = [
      "sudo hostnamectl set-hostname ${var.basename}-${count.index}",
    ]
  }
}

# IPs: use wait_for_lease true or after creation use terraform refresh and terraform show for the ips of domain
output "ip_nodes" {
  value = [libvirt_domain.node.*.network_interface.0.addresses]
}

