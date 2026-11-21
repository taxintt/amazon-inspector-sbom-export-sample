resource "aws_inspector2_enabler" "this" {
  account_ids    = [local.account_id]
  resource_types = ["EC2", "ECR", "LAMBDA"]
}

resource "aws_ecr_registry_scanning_configuration" "this" {
  scan_type = "ENHANCED"

  rule {
    scan_frequency = "CONTINUOUS_SCAN"

    repository_filter {
      filter      = "*"
      filter_type = "WILDCARD"
    }
  }

  depends_on = [aws_inspector2_enabler.this]
}
