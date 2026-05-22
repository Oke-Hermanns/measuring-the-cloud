output "client_public_ip" {
  value = var.assign_public_ip ? stackit_public_ip.client[0].ip : null
}

output "client_private_ip" {
  value = stackit_network_interface.client.ipv4
}

output "server_public_ip" {
  value = var.assign_public_ip ? stackit_public_ip.server[0].ip : null
}

output "server_private_ip" {
  value = stackit_network_interface.server.ipv4
}

output "ssh_private_key_path" {
  value = var.ssh_private_key_path
}

output "ssh_user" {
  value = "ubuntu"
}

output "client_machine_type" {
  value = var.client_machine_type
}

output "server_machine_type" {
  value = var.server_machine_type
}

output "client_availability_zone" {
  value = var.client_availability_zone
}

output "server_availability_zone" {
  value = var.server_availability_zone
}

output "name_prefix" {
  value = local.name_prefix
}

output "network_id" {
  value = local.network_id
}

output "security_group_id" {
  value = local.use_existing_security_group ? var.existing_security_group_id : stackit_security_group.bench[0].security_group_id
}

output "security_group_name" {
  value = local.use_existing_security_group ? null : stackit_security_group.bench[0].name
}

output "instance_affinity" {
  value = var.instance_affinity
}

output "affinity_group_name" {
  value = local.use_affinity_group ? stackit_affinity_group.bench[0].name : null
}

output "affinity_group_policy" {
  value = local.use_affinity_group ? stackit_affinity_group.bench[0].policy : null
}
