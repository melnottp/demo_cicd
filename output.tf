output "guacamole_public_IP" {
  value = flexibleengine_vpc_eip_v1.eip.publicip[0].ip_address
  description = "Guacamole Public IP Address"    
}

output "guacamole_private_IP" {
  value = flexibleengine_compute_instance_v2.instance.access_ip_v4
  description = "Guacamole Private IP Address"  
}

output "keypair_name" {
  value = flexibleengine_compute_keypair_v2.keypair.name
}

output "ssh_port" {
  value = flexibleengine_networking_secgroup_rule_v2.secgroup_rule_ingress4.port_range_min
}

output "vpc_id" {
  description = "ID of the created vpc"
  value       = flexibleengine_vpc_v1.vpc.id
}

output "admin_cidr" {
  value = flexibleengine_networking_subnet_v2.subnet.cidr
}

output "random_id" {
  value = random_string.id.result
  description = "random string value"
}
