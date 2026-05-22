output "runner_public_ip" {
  value = stackit_public_ip.runner.ip
}

output "runner_private_ip" {
  value = stackit_network_interface.runner.ipv4
}

output "ssh_private_key_path" {
  value = var.ssh_private_key_path
}

output "ssh_user" {
  value = "ubuntu"
}

output "network_id" {
  value = stackit_network.main.network_id
}

output "security_group_id" {
  value = stackit_security_group.runner.security_group_id
}

output "security_group_name" {
  value = stackit_security_group.runner.name
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

output "image_id" {
  value = var.image_id
}

output "runner_machine_type" {
  value = var.runner_machine_type
}

output "runner_availability_zone" {
  value = var.runner_availability_zone
}

