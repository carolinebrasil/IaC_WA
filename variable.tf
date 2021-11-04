variable "name_prefix" {
  type        = string
  description = "aws_comm_day_demo_2021"
  default     = "iac_wa_2021"
}

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

variable "region" {
  type    = string
  default = "us-west-2"

}