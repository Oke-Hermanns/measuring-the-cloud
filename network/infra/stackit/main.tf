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
  keypair_name                = local.use_existing_key_pair ? var.existing_key_pair_name : stackit_key_pair.bench[0].name
  affinity_group_policy       = var.instance_affinity == "co-located" ? "hard-affinity" : var.instance_affinity == "different-host" ? "hard-anti-affinity" : ""
  affinity_group_name         = "${local.name_prefix}-affinity"
  use_affinity_group          = var.instance_affinity != "none"
  network_id                  = local.use_existing_network ? var.existing_network_id : stackit_network.main[0].network_id
  security_group_id           = local.use_existing_security_group ? var.existing_security_group_id : stackit_security_group.bench[0].security_group_id

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

check "instance_affinity" {
  assert {
    condition     = contains(["none", "co-located", "different-host"], var.instance_affinity)
    error_message = "instance_affinity must be one of: none, co-located, different-host"
  }
}

resource "stackit_affinity_group" "bench" {
  count      = local.use_affinity_group ? 1 : 0
  project_id = var.stackit_project_id
  name       = local.affinity_group_name
  policy     = local.affinity_group_policy
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

resource "stackit_security_group" "bench" {
  count       = local.use_existing_security_group ? 0 : 1
  project_id  = var.stackit_project_id
  name        = "${local.name_prefix}-sg"
  description = "Network benchmark security group"
  stateful    = true
  labels      = local.labels
}

resource "stackit_security_group_rule" "ssh_ingress" {
  count             = local.use_existing_security_group ? 0 : 1
  project_id        = var.stackit_project_id
  security_group_id = stackit_security_group.bench[0].security_group_id
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
  security_group_id        = stackit_security_group.bench[0].security_group_id
  direction                = "ingress"
  ether_type               = "IPv4"
  remote_security_group_id = stackit_security_group.bench[0].security_group_id
}

resource "stackit_key_pair" "bench" {
  count      = local.use_existing_key_pair ? 0 : 1
  name       = "${local.name_prefix}-key"
  public_key = chomp(file(var.ssh_public_key_path))
  labels     = local.labels
}

resource "stackit_network_interface" "client" {
  project_id         = var.stackit_project_id
  network_id         = local.network_id
  name               = "${local.name_prefix}-client-nic"
  security           = true
  security_group_ids = [local.security_group_id]
  labels             = local.labels
}

resource "stackit_public_ip" "client" {
  count                = local.use_public_ip ? 1 : 0
  project_id           = var.stackit_project_id
  network_interface_id = stackit_network_interface.client.network_interface_id
  labels               = local.labels
}

resource "stackit_network_interface" "server" {
  project_id         = var.stackit_project_id
  network_id         = local.network_id
  name               = "${local.name_prefix}-server-nic"
  security           = true
  security_group_ids = [local.security_group_id]
  labels             = local.labels
}

resource "stackit_public_ip" "server" {
  count                = local.use_public_ip ? 1 : 0
  project_id           = var.stackit_project_id
  network_interface_id = stackit_network_interface.server.network_interface_id
  labels               = local.labels
}

resource "stackit_server" "client" {
  project_id = var.stackit_project_id
  name       = "${local.name_prefix}-client"
  boot_volume = {
    size                  = var.root_volume_size_gib
    source_type           = "image"
    source_id             = var.image_id
    performance_class     = trimspace(var.root_volume_performance_class) != "" ? var.root_volume_performance_class : null
    delete_on_termination = true
  }
  availability_zone = var.client_availability_zone
  machine_type      = var.client_machine_type
  keypair_name      = local.keypair_name
  affinity_group    = local.use_affinity_group ? stackit_affinity_group.bench[0].affinity_group_id : null
  network_interfaces = [
    stackit_network_interface.client.network_interface_id
  ]
  user_data = templatefile("${path.module}/templates/user_data.sh.tftpl", {
    node_role = "client"
  })
  labels = merge(local.labels, {
    role = "client"
  })
  depends_on = [
    stackit_affinity_group.bench
  ]
}

resource "stackit_server" "server" {
  project_id = var.stackit_project_id
  name       = "${local.name_prefix}-server"
  boot_volume = {
    size                  = var.root_volume_size_gib
    source_type           = "image"
    source_id             = var.image_id
    performance_class     = trimspace(var.root_volume_performance_class) != "" ? var.root_volume_performance_class : null
    delete_on_termination = true
  }
  availability_zone = var.server_availability_zone
  machine_type      = var.server_machine_type
  keypair_name      = local.keypair_name
  affinity_group    = local.use_affinity_group ? stackit_affinity_group.bench[0].affinity_group_id : null
  network_interfaces = [
    stackit_network_interface.server.network_interface_id
  ]
  user_data = templatefile("${path.module}/templates/user_data.sh.tftpl", {
    node_role = "server"
  })
  labels = merge(local.labels, {
    role = "server"
  })
  depends_on = [
    stackit_affinity_group.bench
  ]
}
