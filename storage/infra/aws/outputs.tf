output "benchmark_public_ip" {
  value = var.assign_public_ip ? aws_instance.benchmark.public_ip : null
}

output "benchmark_private_ip" {
  value = aws_instance.benchmark.private_ip
}

output "benchmark_ssh_user" {
  value = "ubuntu"
}

output "ssh_private_key_path" {
  value = var.ssh_private_key_path
}

output "vpc_id" {
  value = trimspace(var.existing_vpc_id) != "" ? var.existing_vpc_id : aws_vpc.main[0].id
}

output "security_group_id" {
  value = trimspace(var.existing_security_group_id) != "" ? var.existing_security_group_id : aws_security_group.benchmark[0].id
}

output "security_group_name" {
  value = trimspace(var.existing_security_group_id) != "" ? data.aws_security_group.existing[0].name : aws_security_group.benchmark[0].name
}

output "aws_region" {
  value = var.aws_region
}

output "subnet_cidr" {
  value = var.subnet_cidr
}

output "benchmark_machine_type" {
  value = var.benchmark_machine_type
}

output "benchmark_availability_zone" {
  value = var.aws_availability_zone
}

output "benchmark_block_volume_size_gib" {
  value = var.benchmark_block_volume_size_gib
}

output "benchmark_block_volume_type" {
  value = var.benchmark_block_volume_type
}

output "benchmark_block_volume_id" {
  value = var.benchmark_block_volume_size_gib > 0 ? aws_ebs_volume.block[0].id : null
}

output "benchmark_local_storage" {
  value = var.benchmark_local_storage
}

output "benchmark_local_mount_point" {
  value = var.benchmark_local_mount_point
}

output "benchmark_local_filesystem" {
  value = var.benchmark_local_filesystem
}

output "benchmark_block_filesystem" {
  value = var.benchmark_block_filesystem
}

output "benchmark_block_mount_point" {
  value = var.benchmark_block_mount_point
}
