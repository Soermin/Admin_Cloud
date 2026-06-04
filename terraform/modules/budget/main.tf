resource "aws_budgets_budget" "this" {
  name         = var.budget_name
  budget_type  = "COST"
  limit_amount = var.limit_amount
  limit_unit   = var.limit_unit
  time_unit    = "MONTHLY"

  cost_filter {
    name   = "TagKeyValue"
    values = [format("Project$%s", var.project_tag_value)]
  }

  dynamic "notification" {
    for_each = length(var.subscriber_email_addresses) > 0 ? [1] : []

    content {
      comparison_operator        = "GREATER_THAN"
      threshold                  = var.threshold_percent
      threshold_type             = "PERCENTAGE"
      notification_type          = "ACTUAL"
      subscriber_email_addresses = var.subscriber_email_addresses
    }
  }
}
