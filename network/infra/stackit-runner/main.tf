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
  name_prefix = "${var.project_name}-${random_id.suffix.hex}"
  labels = {
    project = var.project_name
    run     = random_id.suffix.hex
  }
}

check "ssh_key_inputs" {
  assert {
    condition     = trimspace(var.ssh_public_key_path) != ""
    error_message = "ssh_public_key_path is required for the runner foundation stack."
  }
}

resource "stackit_network" "main" {
  project_id       = var.stackit_project_id
  name             = "${local.name_prefix}-network"
  ipv4_prefix      = var.subnet_cidr
  ipv4_nameservers = var.ipv4_nameservers
  routed           = true
  labels           = local.labels
}

resource "stackit_security_group" "runner" {
  project_id  = var.stackit_project_id
  name        = "${local.name_prefix}-sg"
  description = "Cloud Measuring runner security group"
  stateful    = true
  labels      = local.labels
}

resource "stackit_security_group_rule" "ssh_ingress" {
  project_id        = var.stackit_project_id
  security_group_id = stackit_security_group.runner.security_group_id
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
  project_id               = var.stackit_project_id
  security_group_id        = stackit_security_group.runner.security_group_id
  direction                = "ingress"
  ether_type               = "IPv4"
  remote_security_group_id = stackit_security_group.runner.security_group_id
}

resource "stackit_key_pair" "runner" {
  name       = "${local.name_prefix}-runner-key"
  public_key = chomp(file(var.ssh_public_key_path))
  labels     = local.labels
}

resource "stackit_network_interface" "runner" {
  project_id         = var.stackit_project_id
  network_id         = stackit_network.main.network_id
  name               = "${local.name_prefix}-runner-nic"
  ipv4               = cidrhost(var.subnet_cidr, var.runner_private_ip_host)
  security           = true
  security_group_ids = [stackit_security_group.runner.security_group_id]
  labels             = local.labels
}

resource "stackit_public_ip" "runner" {
  project_id           = var.stackit_project_id
  network_interface_id = stackit_network_interface.runner.network_interface_id
  labels               = local.labels
}

resource "stackit_server" "runner" {
  project_id = var.stackit_project_id
  name       = "${local.name_prefix}-runner"
  boot_volume = {
    size                  = var.root_volume_size_gib
    source_type           = "image"
    source_id             = var.image_id
    performance_class     = trimspace(var.root_volume_performance_class) != "" ? var.root_volume_performance_class : null
    delete_on_termination = true
  }
  availability_zone = var.runner_availability_zone
  machine_type      = var.runner_machine_type
  keypair_name      = stackit_key_pair.runner.name
  network_interfaces = [
    stackit_network_interface.runner.network_interface_id
  ]
  user_data = templatefile("${path.module}/../stackit/templates/user_data.sh.tftpl", {
    node_role = "runner"
  })
  labels = merge(local.labels, {
    role = "runner"
  })
}
