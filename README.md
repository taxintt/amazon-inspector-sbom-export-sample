# amazon-inspector-sbom-export-sample

## Disclaimer

This repository intentionally deploys software with known vulnerabilities (PHP and Composer packages) to verify Amazon Inspector SBOM exports.
Do not deploy it in an AWS account that contains production resources or sensitive data.
Use a dedicated AWS account for verification, and destroy the resources when you are done.
The deployed resources (EC2 instances, Inspector scanning, and others) incur AWS charges while they exist.
This repository is provided "as is", without warranty of any kind, under the [MIT License](LICENSE).
The author is not liable for any damages, costs, or security incidents arising from its use.

## Prerequisites

- A dedicated AWS account in which Inspector is not used for anything else.
  `terraform destroy` disables every Inspector scan type that is enabled in the account and resets ECR registry scanning to basic scanning, including settings that existed before this repository was applied.
- Terraform >= 1.16
- AWS CLI with credentials configured.
  The default region is `ap-northeast-1`.
  If you change it, also set `bref_layer_arn` to a layer in the same region.
- Docker, used for `composer install` of the Bref Lambda function and for building container images.
- jq

## Setup

Run every command from the repository root.

1. Create the infrastructure.
   During apply, the zip of the Bref Lambda function is built after running `composer install` in Docker.

   ```sh
   terraform -chdir=terraform init
   terraform -chdir=terraform apply
   ```

2. Build the images under `images/` and push them to the ECR repositories of the same name.

   ```sh
   ./scripts/build-push.sh
   ```

3. Wait until Inspector finishes scanning the EC2 instances, ECR images, and the Lambda function `sbom-python-control`.
   Resources that have not been scanned yet are not included in the SBOM export.
   You can check the progress with `aws inspector2 list-coverage`.
   The Bref function `sbom-php-bref-layer` (runtime `provided.al2023`) never appeared in coverage in our verification, while `sbom-python-control` (runtime `python3.13`) in the same account was scanned within a minute.
   `sbom-python-control` exists only as this comparison.

4. Export the SBOMs in CycloneDX and SPDX formats, and save the printed S3 URIs as tfvars.
   The output goes to a temporary file first, so a failed export does not overwrite the existing tfvars with an empty file.

   ```sh
   tmp="$(mktemp)" && ./scripts/export-sbom.sh > "$tmp" && mv "$tmp" terraform/sbom.auto.tfvars
   ```

5. Run apply again.
   With the S3 URIs from step 4, Terraform creates the Athena named queries `create_cyclonedx` and `create_spdx`.

   ```sh
   terraform -chdir=terraform apply
   ```

6. Run the named queries in the Athena workgroup `inspector-sbom` in this order:
   1. `drop_cyclonedx` and `drop_spdx`, only when the tables already exist from a previous run.
      The tables are external, so dropping them does not delete the SBOMs in S3.
   2. `create_cyclonedx` and `create_spdx`
   3. `repair_cyclonedx` and `repair_spdx`.
      The tables are partitioned by `account` and `resource`, so the partitions must be loaded with `MSCK REPAIR TABLE` before querying.
   4. `cyclonedx_summary` first.
      Confirm that it returns one row per EC2 instance and ECR image, plus one row for `sbom-python-control`.
      A missing resource means it had not been scanned when the SBOM was exported, so repeat step 4 and later steps.
   5. The other analysis queries.
      Set the target CVEs with the `target_cves` variable.

## Cleanup

```sh
terraform -chdir=terraform destroy
```
