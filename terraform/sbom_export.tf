locals {
  inspector_source_conditions = {
    source_account = local.account_id
    source_arn     = "arn:${local.partition}:inspector2:${var.region}:${local.account_id}:report/*"
  }
}

resource "aws_kms_key" "sbom_export" {
  description         = "${var.name_prefix} SBOM export"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.sbom_export_key.json
}

resource "aws_kms_alias" "sbom_export" {
  name          = "alias/${var.name_prefix}-export"
  target_key_id = aws_kms_key.sbom_export.key_id
}

data "aws_iam_policy_document" "sbom_export_key" {
  statement {
    sid       = "EnableIAMPolicies"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:${local.partition}:iam::${local.account_id}:root"]
    }
  }

  statement {
    sid       = "AllowInspectorSbomExport"
    actions   = ["kms:Decrypt", "kms:GenerateDataKey*"]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["inspector2.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.inspector_source_conditions.source_account]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [local.inspector_source_conditions.source_arn]
    }
  }
}

resource "aws_s3_bucket" "sbom_export" {
  bucket        = "${var.name_prefix}-export-${local.account_id}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "sbom_export" {
  bucket = aws_s3_bucket.sbom_export.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sbom_export" {
  bucket = aws_s3_bucket.sbom_export.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.sbom_export.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_policy" "sbom_export" {
  bucket = aws_s3_bucket.sbom_export.id
  policy = data.aws_iam_policy_document.sbom_export_bucket.json

  depends_on = [aws_s3_bucket_public_access_block.sbom_export]
}

data "aws_iam_policy_document" "sbom_export_bucket" {
  statement {
    sid       = "AllowInspectorSbomExport"
    actions   = ["s3:PutObject", "s3:PutObjectAcl", "s3:AbortMultipartUpload"]
    resources = ["${aws_s3_bucket.sbom_export.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["inspector2.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.inspector_source_conditions.source_account]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [local.inspector_source_conditions.source_arn]
    }
  }
}
