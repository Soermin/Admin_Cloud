# Terraform Bootstrap

This layer creates the S3 bucket used by the `dev` Terraform remote states.
It intentionally uses local state first, because the remote backend does not
exist yet.

## Resources

- S3 bucket named `smartfarming-tf-state-<account-id>-<region>` by default.
- Bucket versioning.
- Server-side encryption with S3-managed keys.
- Public access block.
- Bucket owner enforced object ownership.
- Standard tags.

## Commands

```bash
cd terraform/bootstrap
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

After apply, copy the `state_bucket_name` output into the backend commands for
`infra` and `workloads`.

Do not delete this bucket when destroying the application environment. It stores
Terraform state for the environment.
