output "sbom_export_bucket" {
  value = aws_s3_bucket.sbom_export.bucket
}

output "sbom_export_kms_key_arn" {
  value = aws_kms_key.sbom_export.arn
}

output "ecr_repository_urls" {
  value = { for name, repo in aws_ecr_repository.this : name => repo.repository_url }
}

output "athena_workgroup" {
  value = aws_athena_workgroup.this.name
}

output "region" {
  value = var.region
}
