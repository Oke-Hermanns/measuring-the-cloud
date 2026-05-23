variable "project_name" {
  description = "Resource name prefix"
  type        = string
  default     = "cloud-measuring-storage"
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

variable "stackit_availability_zone" {
  description = "STACKIT availability zone"
  type        = string
  default     = "eu01-1"
}

variable "subnet_cidr" {
  description = "Benchmark network IPv4 prefix"
  type        = string
  default     = "10.66.0.0/24"
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
  description = "Path to SSH public key (required only when creating a new STACKIT key pair)"
  type        = string
  default     = ""
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key used by local scripts"
  type        = string
}

variable "existing_key_pair_name" {
  description = "Existing STACKIT key pair name to use. If set, no new key pair is created and ssh_public_key_path is ignored."
  type        = string
  default     = ""
}

variable "existing_network_id" {
  description = "Existing STACKIT network ID to reuse"
  type        = string
  default     = ""
}

variable "existing_security_group_id" {
  description = "Existing STACKIT security group ID to reuse"
  type        = string
  default     = ""
}

variable "assign_public_ip" {
  description = "Whether to assign a public IP to the benchmark VM"
  type        = bool
  default     = true
}

variable "benchmark_image_id" {
  description = "STACKIT image ID for the benchmark VM"
  type        = string
}

variable "benchmark_machine_type" {
  description = "STACKIT machine type for the benchmark VM"
  type        = string
}

variable "benchmark_root_volume_size_gib" {
  description = "Root volume size in GiB for the benchmark VM"
  type        = number
  default     = 30
}

variable "benchmark_root_volume_performance_class" {
  description = "Optional root volume performance class for the benchmark VM"
  type        = string
  default     = ""
}

variable "benchmark_block_volume_size_gib" {
  description = "Attached block volume size in GiB for the benchmark VM"
  type        = number
  default     = 300
}

variable "benchmark_block_volume_performance_class" {
  description = "Optional attached block volume performance class for the benchmark VM"
  type        = string
  default     = "storage_premium_perf6"
}

variable "benchmark_local_mount_point" {
  description = "Mount point for instance-local storage"
  type        = string
  default     = "/mnt/local"
}

variable "benchmark_block_mount_point" {
  description = "Mount point for attached block storage"
  type        = string
  default     = "/mnt/block"
}

variable "benchmark_storage_env_path" {
  description = "Path written by cloud-init describing discovered storage targets"
  type        = string
  default     = "/opt/cloud-measuring/state/storage.env"
}
