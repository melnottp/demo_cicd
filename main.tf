resource "flexibleengine_obs_bucket" "admin_bucket" {
  bucket     = "${var.project}-admin-${random_string.id.result}"
  acl        = "private"
  versioning = true
}

terraform {
  cloud {
    organization = "pmefetest"

    workspaces {
      name = "demo_forrester"
    }
  }

  required_providers {
    flexibleengine = {
      source = "FlexibleEngineCloud/flexibleengine"
    }
  }
}

provider "flexibleengine" {
  domain_name = "OCB0001661"
  tenant_name = "eu-west-0_wb"
  region      = "eu-west-0"
  auth_url    = "https://iam.eu-west-0.prod-cloud-ocb.orange-business.com/v3"
}
    
# Creation of a Key Pair
resource "tls_private_key" "key" {
  algorithm   = "RSA"
  rsa_bits = 4096
}

resource "flexibleengine_compute_keypair_v2" "keypair" {
  name       = "${var.project}-KeyPair-${random_string.id.result}"
  public_key = tls_private_key.key.public_key_openssh
  provisioner "local-exec" {    # Generate "TF-Keypair.pem" in current directory
    command = <<-EOT
      echo '${tls_private_key.key.private_key_pem}' > ./'${var.project}-KeyPair-${random_string.id.result}'.pem
      chmod 400 ./'${var.project}-KeyPair-${random_string.id.result}'.pem
    EOT
  }
}

# Create Virtual Private Cloud
resource "flexibleengine_vpc_v1" "vpc" {
  name = "${var.project}-vpc-${random_string.id.result}"
  cidr = "${var.vpc_cidr}"
}

# Create Frontend network inside the VPC
resource "flexibleengine_networking_port_v2" "front_port" {
  name           = "${var.project}-front_net-${random_string.id.result}"
  network_id     = flexibleengine_vpc_subnet_v1.front_subnet.id
  admin_state_up = "true"
}

# Create Backend network inside the VPC
resource "flexibleengine_networking_port_v2" "back_port" {
  name           = "${var.project}-back_net-${random_string.id.result}"
  network_id     = flexibleengine_vpc_subnet_v1.back_subnet.id
  admin_state_up = "true"
}

# Create Frontend subnet inside the network
resource "flexibleengine_vpc_subnet_v1" "front_subnet" {
  name       = "${var.project}-front_subnet-${random_string.id.result}"
  cidr       = "${var.front_subnet_cidr}"
  gateway_ip = "${var.front_gateway_ip}"
  vpc_id     = flexibleengine_vpc_v1.vpc.id
}

# Create Backend subnet inside the network
resource "flexibleengine_vpc_subnet_v1" "back_subnet" {
  name       = "${var.project}-back_subnet-${random_string.id.result}"
  cidr       = "${var.back_subnet_cidr}"
  gateway_ip = "${var.back_gateway_ip}"
  vpc_id     = flexibleengine_vpc_v1.vpc.id
}

#Create an Elastic IP for Bastion VM
resource "flexibleengine_vpc_eip_v1" "eip" {
  publicip {
    type = "5_bgp"
  }
  bandwidth {
    name        = "${var.project}-Bastion-EIP-${random_string.id.result}"
    size        = 8
    share_type  = "PER"
    charge_mode = "traffic"
  }
}

# Create security group
resource "flexibleengine_networking_secgroup_v2" "secgroup" {
  name = "${var.project}-secgroup-${random_string.id.result}"
}

# Add rules to the security group
resource "flexibleengine_networking_secgroup_rule_v2" "ssh_rule_ingress4" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = "${var.ssh_port}"
  port_range_max    = "${var.ssh_port}"
  remote_ip_prefix  = "${var.remote_ip}"
  security_group_id = flexibleengine_networking_secgroup_v2.secgroup.id
}

# Add rules to access MySQL
resource "flexibleengine_networking_secgroup_rule_v2" "mysql_rule_ingress4" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = "${var.mysql_port}"
  port_range_max    = "${var.mysql_port}"
  remote_ip_prefix  = "${var.back_subnet_cidr}"
  security_group_id = flexibleengine_networking_secgroup_v2.secgroup.id
}

# security group rule to access Bastion
resource "flexibleengine_networking_secgroup_rule_v2" "bastion_rule_ingress4" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = "${var.guacamole_port}"
  port_range_max    = "${var.guacamole_port}"
  remote_ip_prefix  = "${var.any_ip}"
  security_group_id = flexibleengine_networking_secgroup_v2.secgroup.id
}

resource "flexibleengine_networking_secgroup_rule_v2" "secgroup_rule_ingress6" {
  direction         = "ingress"
  ethertype         = "IPv6"
  security_group_id = flexibleengine_networking_secgroup_v2.secgroup.id
}

resource "time_sleep" "wait_for_vpc" {
  create_duration = "30s"
  depends_on = [flexibleengine_vpc_v1.vpc]
}
#Create an Elastic IP for NATGW
resource "flexibleengine_vpc_eip_v1" "eip_natgw" {
  publicip {
    type = "5_bgp"
  }
  bandwidth {
    name        = "${var.project}-NATGW-EIP-${random_string.id.result}"
    size        = 8
    share_type  = "PER"
    charge_mode = "traffic"
  }
}

#Create NAT GW
resource "flexibleengine_nat_gateway_v2" "nat_1" {
  depends_on = [time_sleep.wait_for_vpc]
  name        = "${var.project}-NATGW-${random_string.id.result}"
  description = "demo NATGW for terraform"
  spec        = "1"
  vpc_id      = flexibleengine_vpc_v1.vpc.id
  subnet_id   = flexibleengine_vpc_subnet_v1.front_subnet.id
}

#Add SNAT rule for Frontend subnet
resource "flexibleengine_nat_snat_rule_v2" "snat_1" {
  depends_on = [time_sleep.wait_for_vpc]  
  nat_gateway_id = flexibleengine_nat_gateway_v2.nat_1.id
  floating_ip_id = flexibleengine_vpc_eip_v1.eip_natgw.id
  subnet_id      = flexibleengine_vpc_subnet_v1.front_subnet.id
}

#Add SNAT rule for Backend subnet
resource "flexibleengine_nat_snat_rule_v2" "snat_2" {
  depends_on = [time_sleep.wait_for_vpc]  
  nat_gateway_id = flexibleengine_nat_gateway_v2.nat_1.id
  floating_ip_id = flexibleengine_vpc_eip_v1.eip_natgw.id
  subnet_id      = flexibleengine_vpc_subnet_v1.back_subnet.id
}

#Create ELB
resource "flexibleengine_lb_loadbalancer_v2" "elb_1" {
  depends_on = [time_sleep.wait_for_vpc]  
  description   = "ELB for project ${var.project} (${random_string.id.result})"
  vip_subnet_id = flexibleengine_vpc_subnet_v1.back_subnet.ipv4_subnet_id
  name = "${var.project}-ELB-${random_string.id.result}"
}

#Create an Elastic IP for ELB
resource "flexibleengine_vpc_eip_v1" "eip_elb" {
  publicip {
    type = "5_bgp"
    port_id = flexibleengine_lb_loadbalancer_v2.elb_1.vip_port_id
  }
  bandwidth {
    name        = "${var.project}-ELB-EIP-${random_string.id.result}"
    size        = 8
    share_type  = "PER"
    charge_mode = "traffic"
  }
}

resource "flexibleengine_antiddos_v1" "myantiddos" {
  depends_on = [flexibleengine_vpc_eip_v1.eip_elb]
  floating_ip_id         = flexibleengine_vpc_eip_v1.eip_elb.id
  enable_l7              = true
  traffic_pos_id         = 1
  http_request_pos_id    = 3
  cleaning_access_pos_id = 2
  app_type_id            = 0
}

# Create VM
resource "flexibleengine_compute_instance_v2" "instance" {
  depends_on = [time_sleep.wait_for_vpc]
  name              = "${var.project}-bastion-${random_string.id.result}"
  flavor_id         = "s6.large.2"
  key_pair          = flexibleengine_compute_keypair_v2.keypair.name
  security_groups   = [flexibleengine_networking_secgroup_v2.secgroup.name]
  user_data = data.template_cloudinit_config.config.rendered
  availability_zone = "eu-west-0a"
  network {
    uuid = flexibleengine_vpc_subnet_v1.front_subnet.id
  }
  block_device { # Boots from volume
    uuid                  = "6ab649f9-d0b8-4e4f-aac8-a5d0a3fed1c9"
    source_type           = "image"
    volume_size           = "40"
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = true
    #volume_type           = "SSD"
  }
}

resource "flexibleengine_compute_floatingip_associate_v2" "fip_1" {
  floating_ip = flexibleengine_vpc_eip_v1.eip.publicip.0.ip_address
  instance_id = flexibleengine_compute_instance_v2.instance.id
}

#Create MySQL RDS
resource "flexibleengine_rds_instance_v3" "instance" {
  depends_on = [flexibleengine_vpc_subnet_v1.back_subnet]
  name              = "${var.project}-MySQL-${random_string.id.result}"
  flavor            = "rds.mysql.c6.large.2"
  availability_zone = ["eu-west-0b"]
  security_group_id = flexibleengine_networking_secgroup_v2.secgroup.id
  vpc_id            = flexibleengine_vpc_v1.vpc.id
  subnet_id         = flexibleengine_vpc_subnet_v1.back_subnet.id

  db {
    type     = "MySQL"
    version  = "5.7"
    password = "${var.mysql_password}"
    port     = "3306"
  }
  volume {
    type = "COMMON"
    size = 100
  }
  backup_strategy {
    start_time = "08:00-09:00"
    keep_days  = 1
  }
}

resource "flexibleengine_dns_zone_v2" "services_zone" {
  email ="hostmaster@example.com"
  name = "${var.dns_zone_name}."
  description = "Zone for tooling services"
  zone_type = "private"
  router {
      router_region = "eu-west-0"
      router_id = flexibleengine_vpc_v1.vpc.id
    }
}

resource "flexibleengine_dns_recordset_v2" "mysql_private" {
  zone_id = flexibleengine_dns_zone_v2.services_zone.id
  name = "mysql.${var.dns_zone_name}."
  description = "An example record set"
  type = "A"
  records = ["${flexibleengine_rds_instance_v3.instance.private_ips[0]}"]
}

##Create a CCE Cluster
resource "flexibleengine_cce_cluster_v3" "cluster" {
  depends_on = [time_sleep.wait_for_vpc]
  name                   = "${var.project}-cluster-${random_string.id.result}"
  cluster_type           = "VirtualMachine"
  flavor_id              = "cce.s1.small"
  vpc_id                 = flexibleengine_vpc_v1.vpc.id
  subnet_id              = flexibleengine_vpc_subnet_v1.back_subnet.id
  container_network_type = "vpc-router"
}

resource "flexibleengine_fgs_function" "function" {
  name        = "${var.project}-FGS-${random_string.id.result}"
  app         = "default"
  agency      = "FGSAccessCCE"
  description = "Hibernate CCE cluster"
  handler     = "index.handler"
  memory_size = 128
  timeout     = 3
  runtime     = "Python3.6"
  code_type   = "inline"
  func_code   = <<EOF
# -*- coding:utf-8 -*-
import json
import requests
def handler (event, context):
    Endpoint = "eu-west-0.prod-cloud-ocb.orange-business.com"
    Project = context.getProjectID()
    print("Authentication and Getting token")
    token = context.getToken()
    print("Hibernate CCE latest cluster")
    url = f"https://cce.{Endpoint}/api/v3/projects/{Project}/clusters/${flexibleengine_cce_cluster_v3.cluster.id}/operation/hibernate"
    payload={}
    headers = {
    'Content-Type': 'application/json',
    'X-Auth-Token': token,
    'X-Cluster-UUID': '${flexibleengine_cce_cluster_v3.cluster.id}'
    }
    response = requests.request("POST", url, headers=headers, data=payload)
    print(response.status_code)
    print(response.text)
    return {
        "statusCode": 200,
        "isBase64Encoded": False,
        "body": json.dumps(event),
        "headers": {
            "Content-Type": "application/json"
        }
    }
EOF
}

resource "time_sleep" "wait_for_cce" {
  create_duration = "30s"
  depends_on = [flexibleengine_cce_cluster_v3.cluster]
}

#Create a node inside the CCE cluster
resource "flexibleengine_cce_node_v3" "node_1" {
  depends_on = [time_sleep.wait_for_cce]
  cluster_id        = flexibleengine_cce_cluster_v3.cluster.id
  name              = "${var.project}-node-${random_string.id.result}"
  flavor_id         = "s3.large.2"
  availability_zone = "eu-west-0b"
  key_pair          = flexibleengine_compute_keypair_v2.keypair.name

  root_volume {
    size       = 40
    volumetype = "SATA"
  }
  data_volumes {
    size       = 100
    volumetype = "SATA"
  }
}
