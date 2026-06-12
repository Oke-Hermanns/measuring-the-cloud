output "benchmark_public_ip" {
  value = local.use_public_ip ? stackit_public_ip.benchmark[0].ip : null
}

output "benchmark_private_ip" {
  value = stackit_network_interface.benchmark.ipv4
}

output "benchmark_ssh_user" {
  value = "ubuntu"
}

output "ssh_private_key_path" {
  value = var.ssh_private_key_path
}

output "network_id" {
  value = local.network_id
}

output "security_group_id" {
  value = local.security_group_id
}

output "stackit_project_id" {
  value = var.stackit_project_id
}

output "stackit_region" {
  value = var.stackit_region
}

output "subnet_cidr" {
  value = var.subnet_cidr
}

output "ipv4_nameservers" {
  value = var.ipv4_nameservers
}

output "benchmark_machine_type" {
  value = var.benchmark_machine_type
}

output "benchmark_availability_zone" {
  value = var.stackit_availability_zone
}

output "benchmark_block_volume_size_gib" {
  value = var.benchmark_block_volume_size_gib
}

output "benchmark_local_filesystem" {
  value = var.benchmark_local_filesystem
}

output "benchmark_block_filesystem" {
  value = var.benchmark_block_filesystem
}

output "benchmark_root_volume_size_gib" {
  value = var.benchmark_root_volume_size_gib
}
