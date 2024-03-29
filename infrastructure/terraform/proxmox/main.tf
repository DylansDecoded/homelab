terraform {
  required_providers {
    proxmox = {
      source = "Telmate/proxmox"
      version = "2.9.14"
    }
  }
}

provider "proxmox" {
  # References our vars.tf file to plug in the api_url
  pm_api_url = var.api_url
  # References our secrets.tfvars file to plug in our token_id
  pm_api_token_id = var.token_id
  # References our secrets.tfvars to plug in our token_secret
  pm_api_token_secret = var.token_secret
  # Default to `true` unless you have TLS working within your pve setup
  pm_tls_insecure = true
}


/* Uses cloud-init options from Proxmox 5.2 onward */
resource "proxmox_vm_qemu" "cloudinit" {
  name    = local.vm_name
  desc    = local.vm_description
  vmid    = local.vm_id
  os_type = "cloud-init"
  agent   = 1
  onboot  = local.vm_start_on_boot
  boot    = local.vm_boot_order

  target_node = local.proxmox_node
  pool        = local.proxmox_resource_pool

  clone      = local.template_clone
  full_clone = local.template_full_clone

  cores   = local.cores
  sockets = local.sockets
  memory  = local.memory

  # Disks
  dynamic "disk" {
    for_each = local.disks
    content {
      type    = lookup(disk.value, "type", local.disk_default_type)
      storage = lookup(disk.value, "storage", local.disk_default_storage_pool)
      size    = lookup(disk.value, "size", local.disk_default_size)
      format  = lookup(disk.value, "format", local.disk_default_format)
    }
  }

  # Primary Network
  network {
    model  = local.primary_network.model
    bridge = local.primary_network.bridge
  }

  # Additional Networks - Future

  # Cloud-Init Drive
  ciuser     = local.admin_username
  cipassword = local.admin_password
  sshkeys    = <<-EOF
  %{for key in local.admin_public_ssh_keys~}
  ${key}
  %{endfor~}
  EOF

  # ci_wait = null
  # cicustom = null

  nameserver   = null
  searchdomain = null
  ipconfig0    = join(",", compact(local.ipconfig0_elements))

  tags = join(",", local.tags)

}
