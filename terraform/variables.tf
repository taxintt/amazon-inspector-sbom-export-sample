variable "region" {
  description = "Region in which Inspector and all resources are created"
  type        = string
  default     = "ap-northeast-1"
}

variable "name_prefix" {
  description = "Prefix used for resource names and the Project tag"
  type        = string
  default     = "inspector-sbom"
}

variable "al2023_php84_version" {
  description = "php8.4 version installed on sbom-al2023-php84-vuln (specify a version before the fix)"
  type        = string
  default     = "8.4.26"

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+(-[0-9A-Za-z._]+)?$", var.al2023_php84_version))
    error_message = "al2023_php84_version must be a package version such as 8.4.26 or 8.4.26-1.amzn2023.0.1."
  }
}

variable "bref_layer_arn" {
  description = "ARN of the Bref php-84 layer (https://raw.githubusercontent.com/brefphp/layers.js/main/layers.json)"
  type        = string
  default     = "arn:aws:lambda:ap-northeast-1:873528684822:layer:php-84:25"
}

variable "target_cves" {
  description = "CVE IDs used to filter the impact analysis queries"
  type        = list(string)
  default     = ["CVE-2026-109618", "CVE-2026-109619"]

  validation {
    condition     = length(var.target_cves) > 0 && alltrue([for cve in var.target_cves : can(regex("^CVE-[0-9]{4}-[0-9]+$", cve))])
    error_message = "target_cves must contain at least one ID in the form CVE-YYYY-NNNN."
  }
}

variable "cyclonedx_report_location" {
  description = "S3 URI of the CycloneDX export directly above the account= partition (printed by scripts/export-sbom.sh). When empty, the CREATE TABLE named query is not created"
  type        = string
  default     = ""
}

variable "spdx_report_location" {
  description = "S3 URI of the SPDX export directly above the account= partition (printed by scripts/export-sbom.sh). When empty, the CREATE TABLE named query is not created"
  type        = string
  default     = ""
}
