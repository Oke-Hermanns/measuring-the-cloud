variable "project_name" {
  description = "Resource name prefix"
  type        = string
  default     = "cloud-measuring-runner"
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
  description = "Runner network IPv4 prefix"
  type        = string
  default     = "10.65.0.0/24"
}

variable "ipv4_nameservers" {
  description = "IPv4 nameservers for the runner network"
  type        = list(string)
  default     = ["1.1.1.1", "8.8.8.8"]
}

variable "ssh_ingress_cidr" {
  description = "CIDR allowed to SSH into the runner"
  type        = string
  default     = "0.0.0.0/0"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key used for runner access"
  type        = string
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key used by local scripts to access the runner"
  type        = string
}

variable "image_id" {
  description = "STACKIT image ID for the runner"
  type        = string
  default     = "7b10e105-295b-4369-b6e0-567ec940a02b"
}

variable "runner_machine_type" {
  description = "STACKIT machine type for the runner node"
  type        = string
  default     = "c2i.2"
}

variable "runner_availability_zone" {
  description = "STACKIT availability zone for the runner node"
  type        = string
  default     = "eu01-1"
}

variable "runner_private_ip_host" {
  description = "Host index in subnet CIDR for the runner private IP"
  type        = number
  default     = 10
}

variable "root_volume_size_gib" {
  description = "Root volume size in GiB"
  type        = number
  default     = 30
}

variable "root_volume_performance_class" {
  description = "Optional root volume performance class"
  type        = string
  default     = ""
}
