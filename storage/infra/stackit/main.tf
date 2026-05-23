terraform {
  required_version = ">= 1.6.0"

  required_providers {
    stackit = {
      source  = "stackitcloud/stackit"
      version = "~> 0.94.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "stackit" {
  default_region        = var.stackit_region
  enable_beta_resources = true
}

resource "random_id" "suffix" {
  byte_length = 4
}

locals {
  name_prefix                 = "${var.project_name}-${random_id.suffix.hex}"
  use_existing_key_pair       = trimspace(var.existing_key_pair_name) != ""
  use_existing_network        = trimspace(var.existing_network_id) != ""
  use_existing_security_group = trimspace(var.existing_security_group_id) != ""
  use_public_ip               = var.assign_public_ip
  keypair_name                = local.use_existing_key_pair ? var.existing_key_pair_name : stackit_key_pair.benchmark[0].name
  network_id                  = local.use_existing_network ? var.existing_network_id : stackit_network.main[0].network_id
  security_group_id           = local.use_existing_security_group ? var.existing_security_group_id : stackit_security_group.benchmark[0].security_group_id

  benchmark_local_disk_size_gib_by_machine_type = {
    "c2a.30d"    = 500
    "c2a.60d"    = 1000
    "c2a.120d"   = 1700
    "c2a.240d"   = 3400
    "g2a.30d"    = 500
    "g2a.60d"    = 1000
    "g2a.120d"   = 1700
    "n3.104d.g8" = 1536
  }
  benchmark_local_disk_size_gib = lookup(local.benchmark_local_disk_size_gib_by_machine_type, var.benchmark_machine_type, 0)

  labels = {
    project = var.project_name
    run     = random_id.suffix.hex
  }
}

check "ssh_key_inputs" {
  assert {
    condition     = local.use_existing_key_pair || trimspace(var.ssh_public_key_path) != ""
    error_message = "Set existing_key_pair_name, or provide ssh_public_key_path to create a new STACKIT key pair."
  }
}

resource "stackit_network" "main" {
  count            = local.use_existing_network ? 0 : 1
  project_id       = var.stackit_project_id
  name             = "${local.name_prefix}-network"
  ipv4_prefix      = var.subnet_cidr
  ipv4_nameservers = var.ipv4_nameservers
  routed           = true
  labels           = local.labels
}

resource "stackit_security_group" "benchmark" {
  count       = local.use_existing_security_group ? 0 : 1
  project_id  = var.stackit_project_id
  name        = "${local.name_prefix}-sg"
  description = "Storage benchmark security group"
  stateful    = true
  labels      = local.labels
}

resource "stackit_security_group_rule" "ssh_ingress" {
  count             = local.use_existing_security_group ? 0 : 1
  project_id        = var.stackit_project_id
  security_group_id = stackit_security_group.benchmark[0].security_group_id
  direction         = "ingress"
  ether_type        = "IPv4"
  ip_range          = var.ssh_ingress_cidr
  protocol = {
    name = "tcp"
  }
  port_range = {
    min = 22
    max = 22
  }
}

resource "stackit_security_group_rule" "internal_ingress" {
  count                    = local.use_existing_security_group ? 0 : 1
  project_id               = var.stackit_project_id
  security_group_id        = stackit_security_group.benchmark[0].security_group_id
  direction                = "ingress"
  ether_type               = "IPv4"
  remote_security_group_id = stackit_security_group.benchmark[0].security_group_id
}

resource "stackit_key_pair" "benchmark" {
  count      = local.use_existing_key_pair ? 0 : 1
  name       = "${local.name_prefix}-key"
  public_key = chomp(file(var.ssh_public_key_path))
  labels     = local.labels
}

resource "stackit_network_interface" "benchmark" {
  project_id         = var.stackit_project_id
  network_id         = local.network_id
  name               = "${local.name_prefix}-benchmark-nic"
  security           = true
  security_group_ids = [local.security_group_id]
  labels             = local.labels
}

resource "stackit_public_ip" "benchmark" {
  count                = local.use_public_ip ? 1 : 0
  project_id           = var.stackit_project_id
  network_interface_id = stackit_network_interface.benchmark.network_interface_id
  labels               = local.labels
}

resource "stackit_volume" "block" {
  count             = var.benchmark_block_volume_size_gib > 0 ? 1 : 0
  project_id        = var.stackit_project_id
  name              = "${local.name_prefix}-block"
  availability_zone = var.stackit_availability_zone
  size              = var.benchmark_block_volume_size_gib
  performance_class = trimspace(var.benchmark_block_volume_performance_class) != "" ? var.benchmark_block_volume_performance_class : null
  labels            = local.labels
}

resource "stackit_server" "benchmark" {
  project_id = var.stackit_project_id
  name       = "${local.name_prefix}-benchmark"
  boot_volume = {
    size                  = var.benchmark_root_volume_size_gib
    source_type           = "image"
    source_id             = var.benchmark_image_id
    performance_class     = trimspace(var.benchmark_root_volume_performance_class) != "" ? var.benchmark_root_volume_performance_class : null
    delete_on_termination = true
  }
  availability_zone = var.stackit_availability_zone
  machine_type      = var.benchmark_machine_type
  keypair_name      = local.keypair_name
  network_interfaces = [
    stackit_network_interface.benchmark.network_interface_id
  ]
  user_data = templatefile("${path.module}/templates/user_data.sh.tftpl", {
    benchmark_local_disk_size_gib   = local.benchmark_local_disk_size_gib
    benchmark_block_volume_size_gib = var.benchmark_block_volume_size_gib
    benchmark_local_mount_point     = var.benchmark_local_mount_point
    benchmark_block_mount_point     = var.benchmark_block_mount_point
    benchmark_storage_env_path      = var.benchmark_storage_env_path
  })
  labels = merge(local.labels, {
    role = "benchmark"
  })
}

resource "stackit_server_volume_attach" "block" {
  count      = var.benchmark_block_volume_size_gib > 0 ? 1 : 0
  project_id = var.stackit_project_id
  server_id  = stackit_server.benchmark.server_id
  volume_id  = stackit_volume.block[0].volume_id
}
