# Data source for availability zones
data "alicloud_zones" "default" {
  available_resource_creation = "VSwitch"
}

# Local variables
locals {
  project_name = var.project_name != "" ? var.project_name : read("Please enter the project name: ")

  vpc_name      = "${local.project_name}-${var.stage}-vpc"
  vswitch_name  = "${local.project_name}-${var.stage}-vswitch"
  sg_name       = "${local.project_name}-${var.stage}-sg"
  instance_name = "${local.project_name}-${var.stage}-server"
  rds_name      = "${local.project_name}-${var.stage}-rds"

  common_tags = var.common_tags

  # Retrieve availability zones and define default_zone
  azs         = data.alicloud_zones.default.zones[*].id
  default_zone = local.azs[0]  # Setting the first AZ as the default zone
}

# VPC resource
resource "alicloud_vpc" "vpc" {
  vpc_name   = local.vpc_name
  cidr_block = var.vpc_cidr_block
  tags       = local.common_tags
}

# VSwitch resource
resource "alicloud_vswitch" "vswitch" {
  vpc_id       = alicloud_vpc.vpc.id
  cidr_block   = var.vswitch_cidr
  zone_id      = local.default_zone
  vswitch_name = local.vswitch_name
  tags         = local.common_tags
}

# Security Group resource
resource "alicloud_security_group" "group" {
  security_group_name = local.sg_name
  description         = "Security group for ${var.project_name} in ${var.stage}"
  vpc_id              = alicloud_vpc.vpc.id
  tags                = local.common_tags
}

###################### Security Group Rules ####################################
resource "alicloud_security_group_rule" "allow_ssh" {
  type              = "ingress"
  ip_protocol       = "tcp"
  port_range        = "22/22"
  security_group_id = alicloud_security_group.group.id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "allow_http" {
  type              = "ingress"
  ip_protocol       = "tcp"
  port_range        = "80/80"
  security_group_id = alicloud_security_group.group.id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "allow_mysql" {
  type              = "ingress"
  ip_protocol       = "tcp"
  port_range        = "3306/3306"
  security_group_id = alicloud_security_group.group.id
  cidr_ip           = "0.0.0.0/0"
}

################## MySQL RDS Instance (Publicly Accessible) ######################
resource "alicloud_db_instance" "mysql_rds" {
  engine               = "MySQL"
  engine_version       = "8.0"
  instance_type        = "mysql.n2.medium.1"
  instance_storage     = 20
  instance_name        = local.rds_name
  instance_charge_type = "Postpaid"
  vswitch_id           = alicloud_vswitch.vswitch.id
  security_group_ids   = [alicloud_security_group.group.id]
  security_ips         = ["0.0.0.0/0"]
  
  tags = local.common_tags
}

# MySQL Database Account (Admin with Full Privileges)
resource "alicloud_db_account" "admin_account" {
  db_instance_id      = alicloud_db_instance.mysql_rds.id
  account_name        = "admin_user"
  account_password    = "YourPassword123!"  # Replace with a strong password
  account_description = "Admin account with full privileges for MySQL RDS"
}

# Database (Create a specific database)
resource "alicloud_db_database" "app_db" {
  instance_id   = alicloud_db_instance.mysql_rds.id
  name          = "lms_database"
  character_set = "utf8mb4"
  description   = "Application database"
}

# Grant Full Privileges to the Admin Account
resource "alicloud_db_account_privilege" "admin_privilege" {
  instance_id  = alicloud_db_instance.mysql_rds.id
  account_name = alicloud_db_account.admin_account.account_name
  privilege    = "ReadWrite"
  db_names     = [alicloud_db_database.app_db.name]
}

# Public Connection String (Enable public access)
resource "alicloud_db_connection" "public_connection" {
  instance_id       = alicloud_db_instance.mysql_rds.id
  connection_prefix = "demo-stag-public"
}

####################### ECS ##########################

resource "alicloud_instance" "lms_server" {
  instance_type              = var.instance_type
  image_id                   = "ubuntu_22_04_x64_20G_alibase_20250113.vhd"
  security_groups            = [alicloud_security_group.group.id]
  vswitch_id                 = alicloud_vswitch.vswitch.id
  internet_max_bandwidth_out = 100
  system_disk_size           = 20
  system_disk_category       = "cloud_essd"
  key_name                   = "my-new-key"
  tags                       = local.common_tags
}

resource "null_resource" "provision" {
  connection {
    type        = "ssh"
    user        = "root"
    private_key = file("~/.ssh/my-new-key")
    host        = alicloud_instance.lms_server.public_ip
  }

  provisioner "file" {
    source      = "setup.sh"
    destination = "/root/setup.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /root/setup.sh",
      "DOMAIN=${local.project_name} /root/setup.sh"
    ]
  }

  depends_on = [
    alicloud_instance.lms_server
  ]
}

################ Outputs #################
output "rds_endpoint" {
  value = alicloud_db_instance.mysql_rds.connection_string
}

output "rds_user" {
  value = alicloud_db_account.admin_account.account_name
}

output "rds_password" {
  value     = alicloud_db_account.admin_account.account_password
  sensitive = true
}

output "ecs_public_ip" {
  value = alicloud_instance.lms_server.public_ip
}

output "ecs_ssh_user" {
  value = "root"
}

output "moodle_url" {
  value = "http://${local.project_name}"
}
