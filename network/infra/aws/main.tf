terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = trimspace(var.aws_profile) != "" ? var.aws_profile : null
}

resource "random_id" "suffix" {
  byte_length = 4
}

locals {
  name_prefix                 = "${var.project_name}-${random_id.suffix.hex}"
  use_existing_key_pair       = trimspace(var.existing_key_pair_name) != ""
  use_existing_vpc            = trimspace(var.existing_vpc_id) != ""
  use_existing_security_group = trimspace(var.existing_security_group_id) != ""
  use_existing_nat_gateway    = trimspace(var.existing_nat_gateway_id) != ""
  use_public_ip               = var.assign_public_ip
  use_placement_group         = var.instance_affinity != "none"
  placement_strategy          = var.instance_affinity == "co-located" ? "cluster" : var.instance_affinity == "different-host" ? "spread" : null

  availability_zones = distinct([
    var.client_availability_zone,
    var.server_availability_zone,
  ])

  subnet_cidrs_by_az = {
    for idx, az in local.availability_zones : az => idx == 0 ? var.client_subnet_cidr : var.server_subnet_cidr
  }

  client_private_ip = cidrhost(local.subnet_cidrs_by_az[var.client_availability_zone], var.client_private_ip_host)
  server_private_ip = cidrhost(local.subnet_cidrs_by_az[var.server_availability_zone], var.server_private_ip_host)

  labels = {
    Project = var.project_name
    Run     = random_id.suffix.hex
  }
}

data "aws_vpc" "existing" {
  count = local.use_existing_vpc ? 1 : 0
  id    = var.existing_vpc_id
}

data "aws_internet_gateway" "existing" {
  count = local.use_existing_vpc ? 1 : 0

  filter {
    name   = "attachment.vpc-id"
    values = [var.existing_vpc_id]
  }
}

data "aws_security_group" "existing" {
  count = local.use_existing_security_group ? 1 : 0
  id    = var.existing_security_group_id
}

check "ssh_key_inputs" {
  assert {
    condition     = local.use_existing_key_pair || trimspace(var.ssh_public_key_path) != ""
    error_message = "Set existing_key_pair_name, or provide ssh_public_key_path to create a new AWS key pair."
  }
}

check "existing_network_inputs" {
  assert {
    condition     = local.use_existing_vpc == local.use_existing_security_group
    error_message = "existing_vpc_id and existing_security_group_id must be set together when reusing shared AWS networking."
  }
}

check "private_egress_inputs" {
  assert {
    condition     = local.use_public_ip || !local.use_existing_vpc || local.use_existing_nat_gateway
    error_message = "Set existing_nat_gateway_id when reusing an existing VPC for private benchmark instances with assign_public_ip = false."
  }
}

check "subnet_inputs" {
  assert {
    condition     = var.client_availability_zone == var.server_availability_zone || var.client_subnet_cidr != var.server_subnet_cidr
    error_message = "client_subnet_cidr and server_subnet_cidr must differ when client/server availability zones differ."
  }
}

check "placement_inputs" {
  assert {
    condition     = var.instance_affinity != "co-located" || var.client_availability_zone == var.server_availability_zone
    error_message = "AWS co-located placement uses a cluster placement group and requires client/server in the same availability zone."
  }
}

resource "aws_placement_group" "bench" {
  count    = local.use_placement_group ? 1 : 0
  name     = "${local.name_prefix}-pg"
  strategy = local.placement_strategy

  tags = merge(local.labels, {
    Name             = "${local.name_prefix}-pg"
    InstanceAffinity = var.instance_affinity
  })
}

resource "aws_vpc" "main" {
  count                = local.use_existing_vpc ? 0 : 1
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.labels, {
    Name = "${local.name_prefix}-vpc"
  })
}

resource "aws_internet_gateway" "main" {
  count  = local.use_existing_vpc ? 0 : 1
  vpc_id = aws_vpc.main[0].id

  tags = merge(local.labels, {
    Name = "${local.name_prefix}-igw"
  })
}

resource "aws_subnet" "bench" {
  for_each = local.subnet_cidrs_by_az

  vpc_id                  = local.use_existing_vpc ? data.aws_vpc.existing[0].id : aws_vpc.main[0].id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = local.use_public_ip

  tags = merge(local.labels, {
    Name = "${local.name_prefix}-${each.key}-subnet"
  })
}

resource "aws_route_table" "public" {
  vpc_id = local.use_existing_vpc ? data.aws_vpc.existing[0].id : aws_vpc.main[0].id

  route {
    cidr_block     = "0.0.0.0/0"
    gateway_id     = local.use_public_ip ? (local.use_existing_vpc ? data.aws_internet_gateway.existing[0].id : aws_internet_gateway.main[0].id) : null
    nat_gateway_id = local.use_public_ip ? null : var.existing_nat_gateway_id
  }

  tags = merge(local.labels, {
    Name = "${local.name_prefix}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.bench

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "bench" {
  count       = local.use_existing_security_group ? 0 : 1
  name        = "${local.name_prefix}-sg"
  description = "Network benchmark security group"
  vpc_id      = local.use_existing_vpc ? data.aws_vpc.existing[0].id : aws_vpc.main[0].id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_ingress_cidr]
  }

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.labels, {
    Name = "${local.name_prefix}-sg"
  })
}

resource "aws_key_pair" "bench" {
  count      = local.use_existing_key_pair ? 0 : 1
  key_name   = "${local.name_prefix}-key"
  public_key = chomp(file(var.ssh_public_key_path))

  tags = merge(local.labels, {
    Name = "${local.name_prefix}-key"
  })
}

resource "aws_instance" "client" {
  ami                         = var.image_id
  instance_type               = var.client_machine_type
  availability_zone           = var.client_availability_zone
  subnet_id                   = aws_subnet.bench[var.client_availability_zone].id
  private_ip                  = local.client_private_ip
  vpc_security_group_ids      = [local.use_existing_security_group ? var.existing_security_group_id : aws_security_group.bench[0].id]
  key_name                    = local.use_existing_key_pair ? var.existing_key_pair_name : aws_key_pair.bench[0].key_name
  associate_public_ip_address = local.use_public_ip
  placement_group             = local.use_placement_group ? aws_placement_group.bench[0].name : null

  root_block_device {
    volume_type           = var.root_volume_type
    volume_size           = var.root_volume_size_gib
    delete_on_termination = true
  }

  user_data = templatefile("${path.module}/templates/user_data.sh.tftpl", {
    node_role = "client"
  })

  tags = merge(local.labels, {
    Name = "${local.name_prefix}-client"
    Role = "client"
  })
}

resource "aws_instance" "server" {
  ami                         = var.image_id
  instance_type               = var.server_machine_type
  availability_zone           = var.server_availability_zone
  subnet_id                   = aws_subnet.bench[var.server_availability_zone].id
  private_ip                  = local.server_private_ip
  vpc_security_group_ids      = [local.use_existing_security_group ? var.existing_security_group_id : aws_security_group.bench[0].id]
  key_name                    = local.use_existing_key_pair ? var.existing_key_pair_name : aws_key_pair.bench[0].key_name
  associate_public_ip_address = local.use_public_ip
  placement_group             = local.use_placement_group ? aws_placement_group.bench[0].name : null

  root_block_device {
    volume_type           = var.root_volume_type
    volume_size           = var.root_volume_size_gib
    delete_on_termination = true
  }

  user_data = templatefile("${path.module}/templates/user_data.sh.tftpl", {
    node_role = "server"
  })

  tags = merge(local.labels, {
    Name = "${local.name_prefix}-server"
    Role = "server"
  })
}
