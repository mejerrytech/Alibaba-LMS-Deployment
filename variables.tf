variable "instance_type" {
  type        = string
  default     = "ecs.c6.large"
  description = "Size/type of the server"
}

variable "vpc_cidr_block" {
  type        = string
  default     = "10.110.0.0/16"
  description = "CIDR block for the VPC"
}

variable "vswitch_cidr" {
  type        = string
  default     = "10.110.1.0/24"
  description = "CIDR block for the VSwitch"
}

variable "stage" {
  type        = string
  default     = "stag"
  description = "Stage for the environment"
}

variable "project_name" {
  type        = string
  description = "Project name"
}

variable "vpc_name" {
  type        = string
  description = "Name of the VPC"
}

variable "vswitch_name" {
  type        = string
  description = "Name of the VSwitch"
}

variable "sg_name" {
  type        = string
  description = "Name of the Security Group"
}

variable "instance_name" {
  type        = string
  description = "Name of the ECS instance"
}

variable "rds_name" {
  type        = string
  description = "Name of the RDS instance"
}

variable "common_tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {}
}
