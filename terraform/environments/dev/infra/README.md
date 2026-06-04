# Dev Infra

This layer creates the AWS infrastructure for SmartFarming dev:

- VPC with public and private subnets across multiple AZs.
- Internet Gateway and optional NAT Gateway.
- ECR repositories for `farm-data-service`, `storage-service`, `frontend`, and `iot-simulator`.
- Versioned private S3 bucket for reports.
- Private RDS PostgreSQL with IAM database authentication.
- EKS cluster and managed node group.
- EKS OIDC provider and IRSA roles for `farm-data-service` and `storage-service`.
- GitHub Actions OIDC role for ECR push and workload deployment.
- Monthly AWS Budget.

## First-Time Init

Run `terraform/bootstrap` first, then initialize this layer with the bucket name
from the bootstrap output:

```bash
cd terraform/environments/dev/infra
cp terraform.tfvars.example terraform.tfvars

terraform init \
  -backend-config="bucket=smartfarming-tf-state-<account-id>-<region>" \
  -backend-config="key=smartfarming/dev/infra/terraform.tfstate" \
  -backend-config="region=<region>" \
  -backend-config="encrypt=true" \
  -backend-config="use_lockfile=true"
```

## Validate And Plan

```bash
terraform fmt
terraform validate
terraform plan
```

Only run `terraform apply` after reviewing the plan.

## EKS Version

The default Kubernetes version is `1.34`, which is in Amazon EKS standard
support as of June 4, 2026. Avoid `1.30` for this rebuild because it is already
in extended support and can add extra cluster-hour cost.

## Cost Mode

Default settings run worker nodes in private subnets and create one NAT Gateway.
For lower cost during learning, set:

```hcl
enable_nat_gateway = false
node_subnet_type   = "public"
```

Private nodes without NAT or VPC endpoints will not be able to pull ECR images
or reach AWS APIs. Terraform validates this combination and rejects
`enable_nat_gateway = false` with `node_subnet_type = "private"`.

## RDS IAM Database User

Terraform creates the RDS instance and the IAM permission, but PostgreSQL still
needs the application user inside the database. After infra apply, connect as
the master user using the AWS-managed secret and run:

```sql
CREATE USER farm_app_user;
GRANT rds_iam TO farm_app_user;
GRANT CONNECT ON DATABASE farming TO farm_app_user;
GRANT USAGE, CREATE ON SCHEMA public TO farm_app_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO farm_app_user;
```

The app creates its own tables at startup after the user exists.

## Destroy

Destroy workloads first, then infra:

```bash
cd terraform/environments/dev/workloads
terraform destroy

cd ../infra
terraform destroy
```

Do not destroy the bootstrap state bucket unless you intentionally want to remove
the Terraform backend.
