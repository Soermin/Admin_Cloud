# Dev Environment

Run Terraform from one of these child directories:

- `infra/` for AWS infrastructure.
- `workloads/` for Kubernetes workloads on EKS.

Do not run Terraform from this parent directory.

If a `terraform.tfvars` file exists in this parent directory, treat it as a
local scratch file only. The active variable files should live in `infra/` and
`workloads/`.
