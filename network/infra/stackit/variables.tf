variable "project_name" {
  description = "Resource name prefix"
  type        = string
  default     = "cloud-measuring-net"
}

variable "stackit_project_id" {
  description = "STACKIT project UUID"
  type        = string
}

variable "stackit_region" {
  description = "STACKIT region"
  type        = string
  default     = "eu01"
}

variable "subnet_cidr" {
  description = "Benchmark network IPv4 prefix"
  type        = string
  default     = "10.64.0.0/24"
}

variable "ipv4_nameservers" {
  description = "IPv4 nameservers for the benchmark network"
  type        = list(string)
  default     = ["1.1.1.1", "8.8.8.8"]
}

variable "ssh_ingress_cidr" {
  description = "CIDR allowed to SSH into instances"
  type        = string
  default     = "0.0.0.0/0"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key, required unless existing_key_pair_name is set"
  type        = string
  default     = ""
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key used by local scripts"
  type        = string
}

variable "existing_key_pair_name" {
  description = "Existing STACKIT key pair name. If set, no key pair is created."
  type        = string
  default     = ""
}

variable "existing_network_id" {
  description = "Existing STACKIT network ID. If set, no network is created."
  type        = string
  default     = ""
}

variable "existing_security_group_id" {
  description = "Existing STACKIT security group ID. If set, no security group or rules are created."
  type        = string
  default     = ""
}

variable "assign_public_ip" {
  description = "Whether to assign public IPs to the benchmark client and server"
  type        = bool
  default     = true
}

variable "image_id" {
  description = "STACKIT image ID for both benchmark nodes"
  type        = string
}

variable "client_machine_type" {
  description = "STACKIT machine type for the client node"
  type        = string
}

variable "server_machine_type" {
  description = "STACKIT machine type for the server node"
  type        = string
}

variable "client_availability_zone" {
  description = "STACKIT availability zone for the client node"
  type        = string
}

variable "server_availability_zone" {
  description = "STACKIT availability zone for the server node"
  type        = string
}

variable "client_private_ip_host" {
  description = "Host index in subnet CIDR for the client private IP"
  type        = number
  default     = 10
}

variable "server_private_ip_host" {
  description = "Host index in subnet CIDR for the server private IP"
  type        = number
  default     = 20
}

variable "root_volume_size_gib" {
  description = "Root volume size in GiB"
  type        = number
  default     = 32
}

variable "root_volume_performance_class" {
  description = "Optional root volume performance class"
  type        = string
  default     = ""
}

variable "instance_affinity" {
  description = "Affinity mode for the benchmark client/server pair. none keeps provider default placement, co-located uses hard-affinity, different-host uses hard-anti-affinity."
  type        = string
  default     = "none"

  validation {
    condition     = contains(["none", "co-located", "different-host"], var.instance_affinity)
    error_message = "instance_affinity must be one of: none, co-located, different-host"
  }
}
