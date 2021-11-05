output "vpc_id" {
  description = "The id of VPC"
  value       = aws_vpc.vpc.id
}

# output "web-subnet-1" {
#   description = "Subnet-1"
#   value       = aws_subnet.web-subnet[count.index].id
# }

# output "web-subnet-2" {
#   description = "Subnet-2"
#   value       = aws_subnet.web-subnet-2.id
# }

# output "web-subnet-3" {
#   description = "Subnet-2"
#   value       = aws_subnet.web-subnet-3.id
# }
# output "pv_subnets" {
#   description = "List of private subnets IDs"
#   value = tomap({
#     for i, pv_subnet in aws_subnet.pv_subnet : i => pv_subnet.id
#   })
# }

# output "pub_subnets" {
#   description = "Lists of public subnets IDs"
#   value = tomap({
#     for i, pub_subnet in aws_subnet.pub_subnet : i => pub_subnet.id
#   })
# }

output "budget_type" {
  description = "Budget type"
  value       = aws_budgets_budget.iac_wa_cost.budget_type

}

output "av_zn" {
  value = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

# output "elb-dns" {
#   description = "The DNS of ELB"
#   value       = aws_elb.iac_elb1.dns_name
# }

output "lb-dns" {
  description = "The DNS of ALB"
  value       = aws_lb.iac_lb1.dns_name
}