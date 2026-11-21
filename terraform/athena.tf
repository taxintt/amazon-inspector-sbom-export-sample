resource "aws_glue_catalog_database" "this" {
  name = "inspector_sbom"
}

resource "aws_athena_workgroup" "this" {
  name          = var.name_prefix
  force_destroy = true

  configuration {
    enforce_workgroup_configuration = true

    engine_version {
      selected_engine_version = "Athena engine version 3"
    }

    managed_query_results_configuration {
      enabled = true
    }
  }
}

locals {
  target_cves_sql = join(", ", [for cve in var.target_cves : "'${cve}'"])

  table_ddl = {
    cyclonedx = var.cyclonedx_report_location
    spdx      = var.spdx_report_location
  }

  analysis_queries = [
    "cyclonedx_summary",
    "cyclonedx_php_components",
    "cyclonedx_affected_packages",
    "cyclonedx_composer_vulnerabilities",
    "spdx_php_packages",
    "spdx_affected_packages",
  ]
}

resource "aws_athena_named_query" "create_table" {
  for_each = { for name, location in local.table_ddl : name => location if location != "" }

  name      = "create_${each.key}"
  workgroup = aws_athena_workgroup.this.id
  database  = aws_glue_catalog_database.this.name
  query     = templatefile("${path.module}/sql/create_${each.key}.sql", { location = each.value })
}

resource "aws_athena_named_query" "maintenance" {
  for_each = toset(flatten([for name in keys(local.table_ddl) : ["repair_${name}", "drop_${name}"]]))

  name      = each.key
  workgroup = aws_athena_workgroup.this.id
  database  = aws_glue_catalog_database.this.name
  query     = replace(replace(each.key, "repair_", "MSCK REPAIR TABLE "), "drop_", "DROP TABLE IF EXISTS ")
}

resource "aws_athena_named_query" "analysis" {
  for_each = toset(local.analysis_queries)

  name      = each.key
  workgroup = aws_athena_workgroup.this.id
  database  = aws_glue_catalog_database.this.name
  query     = templatefile("${path.module}/sql/${each.key}.sql", { target_cves = local.target_cves_sql })
}
