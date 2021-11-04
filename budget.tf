resource "aws_budgets_budget" "iac_wa_cost" {
  name              = "iac_wa_budget"
  budget_type       = "COST"
  limit_amount      = "3"
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = "2021-10-01_00:00"
  time_period_end   = "2021-12-01_23:59"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 50
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED" #ACTUAL
    subscriber_email_addresses = ["adassathomaz1@gmail.com","luananadielle@gmail.com","icarolinebrasil@gmail.com"]

  }
}