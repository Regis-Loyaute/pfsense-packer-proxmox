  packer {
    required_plugins {
      name = {
        version = "1.1.7"
        source  = "github.com/hashicorp/proxmox"
      }
    }
  }

  #############################################################
  # Proxmox variables
  #############################################################
  variable "proxmox_hostname" {
    description = "Proxmox host address (e.g. https://65.109.39.27:8006)"
    type = string
    sensitive = true
  }

  variable "proxmox_token_user" {
    description = "Proxmox token user (e.g. root@pam!root)"
    type = string
    sensitive = true
  }

  variable "proxmox_token" {
    description = "Proxmox token for the provided proxmox_token_user"
    type = string
    sensitive = true
  }

  variable "proxmox_node_name" {
    description = "Proxmox node"
    type = string
  }

  variable "proxmox_insecure_skip_tls_verify" {
    description = "Skip TLS verification?"
    type = bool
    default = true
  }

  #############################################################
  # Template variables
  #############################################################

  variable "vm_id" {
    description = "VM template ID"
    type = number
    default = 900
  }

  variable "vm_name" {
    description = "VM name"
    type = string
    default = "pfSense-firewall"
  }

  variable "vm_storage_pool" {
    description = "Storage where template will be stored"
    type = string
    default = "local-lvm"
  }

  variable "vm_storage_pool_type" {
    description = "Type of storage where template will be stored"
    type = string
    default = "lvm"
  }

  variable "vm_cores" {
    description = "VM amount of memory"
    type = number
    default = 2
  }

  variable "vm_memory" {
    description = "VM amount of memory"
    type = number
    default = 2048
  }

  variable "vm_sockets" {
    description = "VM amount of CPU sockets"
    type = number
    default = 1
  }

  variable "iso_checksum" {
    type = string
    description = "Checksum of the ISO file"
  }

  variable "iso_file" {
    description = "Location of ISO file on the server. E.g. local:iso/pfSense-CE-2.7.2-RELEASE-amd64.iso"
    type = string
  }

  #############################################################
  # OS Settings
  #############################################################
  variable "lan_ip" {
    description = "IP of the LAN interface"
    type = string
    default = "192.168.10.254"
  }

  variable "lan_mask" {
    description = "Mask of the LAN IP"
    type = string
    default = "24"
  }

  variable "wan_ip" {
    description = "IP of the WAN interface"
    type = string
    default = "10.0.0.2"
  }

  variable "wan_mask" {
    description = "Mask of the WAN IP"
    type = string
    default = "30"
  }

  variable "wan_gw" {
    description = "Gateway of the WAN interface"
    type = string
    default = "10.0.0.1"
  }

  variable "pfsense_default_username" {
    description = "Default pfsense username"
    type = string
    default = "root"
  }

  variable "pfsense_default_password" {
    description = "Default pfsense password"
    type = string
    default = "pfsense"
  }

  source "proxmox-iso" "pfsense_template" {
    proxmox_url               = "${var.proxmox_hostname}/api2/json"
    insecure_skip_tls_verify 	= var.proxmox_insecure_skip_tls_verify
    username                  = var.proxmox_token_user
    token                     = var.proxmox_token
    node                      = var.proxmox_node_name

    communicator = "none" // Explicitly set the communicator to none


    vm_name   = var.vm_name
    vm_id     = var.vm_id

    qemu_agent = false

    memory    = var.vm_memory
    sockets   = var.vm_sockets
    cores     = var.vm_cores
    os        = "other"

    network_adapters {
          model   = "virtio"
          bridge  = "vmbr1"
          firewall = true
    }

    network_adapters {
          model   = "virtio"
          bridge  = "vmbr2"
          firewall = true
    }

    disks {
      type              = "virtio"
      disk_size         = "10G"
      storage_pool      = var.vm_storage_pool
      storage_pool_type = var.vm_storage_pool_type
      format            = "qcow2"
    }

    iso_file              = var.iso_file
    iso_checksum          = var.iso_checksum

    onboot                = true

    template_name         = var.vm_name
    unmount_iso           = true

    http_directory        = "./http"
    boot_wait             = "45s"
    boot_command = [
      "<enter><wait2>", # Accept terms and conditions
      "<enter><wait2>", # Install pfSense
      "<enter><wait2>", # Continue with default keyboard mapping
      "<enter><wait2>", # Auto (ZFS)
      "<enter><wait2>", # Select 'stripe' (No redundancy) and confirm
      "<spacebar><wait2>", # Select disk 'vtbd0'
      "<enter><wait10>", # Confirm disk selection
      "y<wait1m>", # Confirm ZFS configuration
      "n<wait2>", # No additional manual configuration
      "<enter><wait1.5m>", # Reboot

      "n<enter><wait2>vtnet0<enter><wait2>vtnet1<enter><wait2>", # Setup WAN and LAN interfaces

      "y<enter><wait3m>", # Increase the wait time if your pfsense install is slow

      "2<enter>1<enter><wait1>n<enter><wait1>${var.wan_ip}<enter><wait2>${var.wan_mask}<enter>", # Setup WAN IP addresses

      "${var.wan_gw}<enter><wait1>y<enter><wait1>n<enter><wait1><enter><wait1>n<enter><wait1>n<enter><enter><wait10>", # Setup WAN gateway and complete WAN setup

      "2<enter>2<enter>n<enter>${var.lan_ip}<enter><wait2>${var.lan_mask}<enter>", # Setup LAN IP addresses

      "<enter><wait1>n<enter><wait1><enter><5><enter>n<enter><wait1>n<enter><wait1><enter>" # Complete LAN setup and finalize configuration
  ] 
}

  build {
    sources = [
      "source.proxmox-iso.pfsense_template"
    ]
  } 