# SmartFarming Cloud Admin

SmartFarming is a learning project for running a greenhouse monitoring system on
AWS with reproducible Infrastructure as Code.

## Services

- `farm-data-service`: FastAPI service that receives IoT telemetry, stores data
  in PostgreSQL/RDS, and exposes metrics APIs.
- `storage-service`: FastAPI service that stores report files in S3.
- `frontend-app`: Nginx static dashboard that proxies API calls to the backend
  services.
- `iot-simulator`: Python process that sends synthetic telemetry to
  `farm-data-service`.

## Cloud Architecture

The Terraform rebuild uses this AWS architecture:

- VPC with public and private subnets across at least two AZs.
- Optional NAT Gateway for private subnet egress.
- ECR repositories for all application images.
- EKS managed cluster and managed node group using a Kubernetes version in
  standard support.
- Private RDS PostgreSQL with IAM database authentication.
- Private S3 reports bucket with versioning, encryption, public access block,
  and lifecycle policy.
- IRSA roles:
  - `storage-service` can access the reports S3 bucket.
  - `farm-data-service` can connect to RDS using IAM auth.
- GitHub Actions OIDC role for image build/push and workload deployment.
- AWS Budget filtered by `Project$smartfarming`.

## Data Flow

1. `iot-simulator` sends telemetry to `farm-data-service`.
2. `farm-data-service` stores telemetry in RDS PostgreSQL.
3. `frontend` reads metrics, daily chart data, harvest progress, and energy
   usage through Nginx proxy paths.
4. Users upload reports through the frontend.
5. `storage-service` stores reports in S3 using IRSA, without static AWS keys.

## Terraform Layout

```text
terraform/
  bootstrap/
  environments/dev/infra/
  environments/dev/workloads/
  modules/
    budget/
    ecr/
    eks/
    github-oidc/
    irsa/
    k8s-app/
    rds/
    s3/
    vpc/
```

`bootstrap` owns the remote state bucket and should not be destroyed with the
application environment. `infra` owns AWS infrastructure. `workloads` owns
Kubernetes resources inside EKS.

## Build Images

For local/manual build and push:

```bash
AWS_REGION=ap-southeast-1
AWS_ACCOUNT_ID=<account-id>
IMAGE_TAG=<commit-sha>

aws ecr get-login-password --region "$AWS_REGION" \
  | docker login --username AWS --password-stdin \
  "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

docker build -t "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/farm-data-service:$IMAGE_TAG" farm-data-service
docker build -t "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/storage-service:$IMAGE_TAG" storage-service
docker build -t "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/frontend:$IMAGE_TAG" frontend-app
docker build -t "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/iot-simulator:$IMAGE_TAG" iot-simulator

docker push "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/farm-data-service:$IMAGE_TAG"
docker push "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/storage-service:$IMAGE_TAG"
docker push "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/frontend:$IMAGE_TAG"
docker push "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/iot-simulator:$IMAGE_TAG"
```

## Deploy Order

1. Bootstrap state bucket:

```bash
cd terraform/bootstrap
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

2. Deploy infra:

```bash
cd terraform/environments/dev/infra
cp terraform.tfvars.example terraform.tfvars

terraform init \
  -backend-config="bucket=smartfarming-tf-state-<account-id>-<region>" \
  -backend-config="key=smartfarming/dev/infra/terraform.tfstate" \
  -backend-config="region=<region>" \
  -backend-config="encrypt=true" \
  -backend-config="use_lockfile=true"

terraform fmt
terraform validate
terraform plan
terraform apply
```

3. Create the RDS IAM database user:

```sql
CREATE USER farm_app_user;
GRANT rds_iam TO farm_app_user;
GRANT CONNECT ON DATABASE farming TO farm_app_user;
GRANT USAGE, CREATE ON SCHEMA public TO farm_app_user;
```

4. Build/push images.

5. Deploy workloads:

```bash
cd terraform/environments/dev/workloads
cp terraform.tfvars.example terraform.tfvars

terraform init \
  -backend-config="bucket=smartfarming-tf-state-<account-id>-<region>" \
  -backend-config="key=smartfarming/dev/workloads/terraform.tfstate" \
  -backend-config="region=<region>" \
  -backend-config="encrypt=true" \
  -backend-config="use_lockfile=true"

terraform fmt
terraform validate
terraform plan -var="image_tag=<commit-sha>"
terraform apply -var="image_tag=<commit-sha>"
```

## Destroy Order

Destroy workloads first, then infra:

```bash
cd terraform/environments/dev/workloads
terraform destroy

cd ../infra
terraform destroy
```

Do not destroy `terraform/bootstrap` unless you intentionally want to remove the
state backend.

## Cost Saving

- Set `enable_nat_gateway = false` and `node_subnet_type = "public"` for a lower
  cost learning setup.
- Keep `eks_cluster_version` on an Amazon EKS standard-support version to avoid
  extended support charges.
- Keep node sizes small, for example `t3.small`.
- Keep `node_desired_size = 1` or `2`.
- Keep `budget_enabled = true`.
- Destroy workloads and infra when you are done for the day.
- Keep the reports bucket lifecycle policy enabled.

## CI/CD

`.github/workflows/deploy-eks.yml` uses GitHub OIDC, not static AWS keys.
It builds all four images, pushes them to ECR with `github.sha`, then runs
Terraform workloads apply with `image_tag=${{ github.sha }}`.

Terraform deploy is more reproducible than `kubectl set image` because the
desired Kubernetes objects and image tag are stored in Terraform state. The
trade-off is that Terraform now owns the Kubernetes workload lifecycle, so manual
`kubectl` changes can be reverted by the next apply.

## Troubleshooting

- EKS nodes cannot pull images: if NAT is disabled, use public node subnets or
  add VPC endpoints for ECR, S3, STS, and CloudWatch Logs.
- `farm-data-service` cannot connect to RDS: verify the PostgreSQL user exists,
  has `rds_iam`, and matches `RDS_DB_USER`.
- `storage-service` cannot access S3: verify the ServiceAccount annotation and
  IRSA role ARN output from infra.
- HPA shows unknown metrics: install or enable metrics-server in the cluster.
- GitHub Actions cannot deploy: verify `AWS_GHA_ROLE_ARN`, `TF_STATE_BUCKET`,
  `AWS_REGION`, and `AWS_ACCOUNT_ID` repository settings.
