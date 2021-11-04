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

#Network
variable "pvAZ_CIDRblocks" {
  type = map(string)
  default = {
    a = "10.0.10.0/24",
    b = "10.0.20.0/24",
    c = "10.0.30.0/24"
  }
}

variable "pubAZ_CIDRblocks" {
  type = map(string)
  default = {
    a = "10.0.110.0/24",
    b = "10.0.120.0/24",
    c = "10.0.130.0/24"
  }
}

variable "pvIPv6_prefix" {
  type = map(number)
  default = {
    a = 1,
    b = 2,
    c = 3
  }
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
  default     = "/users/caroline/.ssh/id_rsa.pub"

}