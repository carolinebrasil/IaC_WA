# Commons
variable "name_prefix" {
  type        = string
  description = "aws_comm_day_demo_2021"
  default     = "iac_wa_2021"
}

variable "region" {
  type    = string
  default = "us-west-2"
}

variable "item_count" {
  description = "Count to set AZs and instances"
  type        = number
  default     = 3
}

# Network
variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

# Subnets
variable "pub_subnet_cidr" {
  type    = list(string)
  default = ["10.0.10.0/24", "10.0.20.0/24", "10.0.30.0/24"]
}

variable "pv_subnet_cidr" {
  type    = list(string)
  default = ["10.0.110.0/24", "10.0.120.0/24", "10.0.130.0/24"]
}
# AZs
variable "az_names" {
  type    = list(string)
  default = ["us-west-2a", "us-west-2b", "us-west-2c"]
}


# Compute
variable "ami" {
  description = "AMI"
  default     = "ami-0e5b6b6a9f3db6db8"
}

variable "instance_type" {
  default     = "t2.micro"
  description = "Ec2 instance type"
}

variable "key_path" {
  description = "SSH key to access ec2 instances"
  default     = "/home/caroline/.ssh/id_rsa.pub"

}