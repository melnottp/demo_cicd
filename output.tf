output "bastion_public_IP" {
  value = flexibleengine_vpc_eip_v1.eip.publicip[0].ip_address
  description = "Bastion public IP Address"    
}

output "bastion_private_IP" {
  value = flexibleengine_compute_instance_v2.instance.access_ip_v4
  description = "Guacamole Private IP Address"  
}

output "keypair_name" {
  value = flexibleengine_compute_keypair_v2.keypair.name
}

output "keypair" {
  value = tls_private_key.key.private_key_pem
  sensitive = true
}

output "ssh_port" {
  value = flexibleengine_networking_secgroup_rule_v2.ssh_rule_ingress4.port_range_min
}

output "vpc_id" {
  description = "ID of the created vpc"
  value       = flexibleengine_vpc_v1.vpc.id
}

output "frontend_cidr" {
  value = flexibleengine_vpc_subnet_v1.front_subnet.cidr
}

output "backend_cidr" {
  value = flexibleengine_vpc_subnet_v1.back_subnet.cidr
}

output "random_id" {
  value = random_string.id.result
  description = "random string value"
}

output "kubeconfig_json" {
  value = local.kubectl_config_json
  sensitive = true
}

output "elb_id" {
  description = "ID of the created vpc"
  value       = flexibleengine_lb_loadbalancer_v2.elb_1.id
}

output "ELB_public_IP" {
  value = flexibleengine_vpc_eip_v1.eip_elb.publicip[0].ip_address
  description = "ELB public IP Address"    
}
