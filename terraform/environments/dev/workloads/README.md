# Dev Workloads

This layer deploys SmartFarming workloads into EKS with the Kubernetes provider.
It reads infra outputs from the `infra` Terraform state by default.

Managed Kubernetes resources:

- Namespaces: `farm-data`, `storage`, `frontend`.
- ServiceAccounts:
  - `farm-data/farm-data-service` annotated with the RDS IAM IRSA role.
  - `storage/storage-service` annotated with the S3 IRSA role.
  - `frontend/frontend`.
  - `farm-data/iot-simulator`.
- ConfigMaps for farm data, storage, and simulator configuration.
- Deployments for all four services.
- ClusterIP Services for all four workloads.
- HPA for `farm-data-service`, `storage-service`, and `frontend`.

`iot-simulator` is intentionally fixed at one replica and has no HPA, so it does
not duplicate telemetry generation.

## First-Time Init

```bash
cd terraform/environments/dev/workloads
cp terraform.tfvars.example terraform.tfvars

terraform init \
  -backend-config="bucket=smartfarming-tf-state-<account-id>-<region>" \
  -backend-config="key=smartfarming/dev/workloads/terraform.tfstate" \
  -backend-config="region=<region>" \
  -backend-config="encrypt=true" \
  -backend-config="use_lockfile=true"
```

## Validate And Plan

```bash
terraform fmt
terraform validate
terraform plan -var="image_tag=<commit-sha>"
```

Only run `terraform apply` after:

1. Infra exists.
2. ECR images for the selected tag already exist.
3. The RDS app user has been created and granted `rds_iam`.

## Destroy

Destroy workloads before infra:

```bash
terraform destroy
```
