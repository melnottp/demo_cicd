variable "project" {
  default = "forrester"
  description = "Short descriptive, readable label of the project you are working on. Is utilized as a part of resource names."
}

variable "remote_ip" {
  default = "90.84.172.45/32"
  description = "remote IP allowed for ssh access to Bastion"
}

variable "any_ip" {
  default = "0.0.0.0/0"
  description = "remote IP allowed for ssh access to Bastion"
}

variable "ssh_port" {
  default = "4444"
  description = "ssh port to access Bastion."
}

variable "mysql_port" {
  default = "3306"
  description = "ssh port to access Bastion."
}

variable "guacamole_port" {
  default = "8443"
  description = "HTTPS access to Guacamole"
}

variable "vpc_cidr" {
  default = "192.168.0.0/16"
  description = "VPC CIDR."
}

variable "front_subnet_cidr" {
  default = "192.168.1.0/24"
  description = "Subnet CIDR."
}

variable "back_subnet_cidr" {
  default = "192.168.2.0/24"
  description = "Subnet CIDR."
}

variable "front_gateway_ip" {
  default = "192.168.1.1"
  description = "Subnet gateway IP."
}

variable "back_gateway_ip" {
  default = "192.168.2.1"
  description = "Subnet gateway IP."
}

# ID String for resources
resource "random_string" "id" {
  length  = 4
  special = false
  upper   = false
}

variable "cloud_init_path" {
  description = "Path to directory with custom Cloud-init configuration. Cloud-init cloud config format is expected. Only *.yml and *.yaml files will be read."
  default     = "./"
}

variable "primary_az" {
  default = "eu-west-0b"
  description = "RDS primary AZ"
}

variable "standby_az" {
  default = "eu-west-0c"
  description = "RDS primary AZ"
}

variable "mysql_password" {
  default = "PaSsW0rd22!"
  description = "RDS primary AZ"
}

variable "dns_zone_name" {
  default = "forrester.services"
  description = "private DNS zone"
}
