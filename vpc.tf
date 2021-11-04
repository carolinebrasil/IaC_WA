resource "aws_vpc" "vpc" {
  cidr_block                       = "10.0.0.0/16"
  enable_dns_support               = true
  enable_dns_hostnames             = true
  enable_classiclink               = false
  assign_generated_ipv6_cidr_block = true

  tags = {
    "Name" = "${var.name_prefix}-vpc"
  }

}

resource "aws_subnet" "pv_subnet" {
  for_each = var.pvAZ_CIDRblocks

  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = each.value
  map_public_ip_on_launch = false
  availability_zone       = "${var.region}${each.key}"
  ipv6_cidr_block         = cidrsubnet(aws_vpc.vpc.ipv6_cidr_block, 8, var.pvIPv6_prefix[each.key])

  tags = {
    "Name" = "${var.name_prefix}-pv-subnet-${each.key}"
  }

}

resource "aws_subnet" "pub_subnet" {
  for_each = var.pubAZ_CIDRblocks

  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = each.value
  map_public_ip_on_launch = true
  availability_zone       = "${var.region}${each.key}"

  tags = {
    "Name" = "${var.name_prefix}-pub-subnet-${each.key}"
  }

}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    "Name" = "${var.name_prefix}-igw"
  }

}

resource "aws_egress_only_internet_gateway" "egress_internet_gw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    "Name" = "${var.name_prefix}-egress-internet-gw"
  }

}

resource "aws_default_route_table" "default_route" {
  default_route_table_id = aws_vpc.vpc.default_route_table_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    "Name" = "${var.name_prefix}-default-route-table"
  }
  depends_on = [
    aws_internet_gateway.igw
  ]
}

resource "aws_route_table_association" "pub_subnet_association" {
  for_each       = aws_subnet.pub_subnet
  subnet_id      = each.value.id
  route_table_id = aws_default_route_table.default_route.id
}

resource "aws_route_table" "pv_route_table" {
  vpc_id = aws_vpc.vpc.id
  route {
    ipv6_cidr_block        = "::/0"
    egress_only_gateway_id = aws_egress_only_internet_gateway.egress_internet_gw.id
  }
  tags = {
    "Name" = "${var.name_prefix}-pv-route-table"
  }
  depends_on = [
    aws_egress_only_internet_gateway.egress_internet_gw
  ]

}

resource "aws_route_table_association" "pv_subnet_association" {
  for_each       = var.pvAZ_CIDRblocks
  route_table_id = aws_route_table.pv_route_table.id
  subnet_id      = aws_subnet.pv_subnet[each.key].id
}