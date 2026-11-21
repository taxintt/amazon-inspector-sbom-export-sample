#!/bin/sh
# Export CycloneDX and SPDX SBOMs, and print the S3 URIs used as the Athena table LOCATION in tfvars format
set -eu

root="$(cd "$(dirname "$0")/.." && pwd)"
bucket="$(terraform -chdir="$root/terraform" output -raw sbom_export_bucket)"
kms_key_arn="$(terraform -chdir="$root/terraform" output -raw sbom_export_kms_key_arn)"
region="$(terraform -chdir="$root/terraform" output -raw region)"

export_sbom() {
  format="$1"
  prefix="$2"

  report_id="$(aws --region "$region" inspector2 create-sbom-export \
    --report-format "$format" \
    --s3-destination "bucketName=$bucket,keyPrefix=$prefix,kmsKeyArn=$kms_key_arn" \
    --query reportId --output text)"
  echo "$format: reportId=$report_id" >&2

  i=0
  while :; do
    i=$((i + 1))
    if [ "$i" -gt 120 ]; then
      echo "$format: export did not finish within 30 minutes (reportId=$report_id)" >&2
      exit 1
    fi
    status="$(aws --region "$region" inspector2 get-sbom-export --report-id "$report_id" --query status --output text)"
    echo "$format: $status" >&2
    case "$status" in
      SUCCEEDED) break ;;
      FAILED | CANCELLED)
        aws --region "$region" inspector2 get-sbom-export --report-id "$report_id" >&2
        exit 1
        ;;
    esac
    sleep 15
  done

  key="$(aws --region "$region" s3api list-objects-v2 --bucket "$bucket" --prefix "$prefix/" \
    --query "Contents[?contains(Key, '$report_id') && contains(Key, '/account=')].Key | [0]" --output text)"
  if [ "$key" = "None" ]; then
    echo "$format: no SBOM object for reportId=$report_id under s3://$bucket/$prefix/" >&2
    exit 1
  fi
  echo "s3://$bucket/${key%%/account=*}/"
}

cyclonedx="$(export_sbom CYCLONEDX_1_4 cyclonedx)"
spdx="$(export_sbom SPDX_2_3 spdx)"

cat <<EOF
cyclonedx_report_location = "$cyclonedx"
spdx_report_location      = "$spdx"
EOF
