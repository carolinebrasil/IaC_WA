output "vpc_id" {
  description = "The id of VPC"
  value       = aws_vpc.vpc.id
}

output "pv_subnets" {
  description = "List of private subnets IDs"
  value = tomap({
    for i, pv_subnet in aws_subnet.pv_subnet : i => pv_subnet.id
  })
}

output "pub_subnets" {
  description = "Lists of public subnets IDs"
  value = tomap({
    for i, pub_subnet in aws_subnet.pub_subnet : i => pub_subnet.id
  })
}

output "budget_type" {
  description = "Budget type"
  value = aws_budgets_budget.iac_wa_cost.budget_type
  
}