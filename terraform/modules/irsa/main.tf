data "tls_certificate" "oidc" {
  url = var.oidc_issuer_url
}

locals {
  oidc_provider_url = replace(var.oidc_issuer_url, "https://", "")
  thumbprint_list   = length(var.oidc_thumbprint_list) > 0 ? var.oidc_thumbprint_list : [data.tls_certificate.oidc.certificates[0].sha1_fingerprint]

  service_accounts = {
    farm_data = {
      namespace       = var.farm_data_namespace
      service_account = var.farm_data_service_account
      role_name       = "${var.name_prefix}-farm-data-irsa"
    }
    storage = {
      namespace       = var.storage_namespace
      service_account = var.storage_service_account
      role_name       = "${var.name_prefix}-storage-irsa"
    }
  }
}

resource "aws_iam_openid_connect_provider" "eks" {
  url             = var.oidc_issuer_url
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = local.thumbprint_list

  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-eks-oidc"
    Service = "irsa"
  })
}

data "aws_iam_policy_document" "assume_role" {
  for_each = local.service_accounts

  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_url}:sub"
      values   = ["system:serviceaccount:${each.value.namespace}:${each.value.service_account}"]
    }
  }
}

resource "aws_iam_role" "this" {
  for_each = local.service_accounts

  name               = each.value.role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role[each.key].json

  tags = merge(var.tags, {
    Name    = each.value.role_name
    Service = "irsa"
  })
}

data "aws_iam_policy_document" "storage_s3" {
  statement {
    sid    = "AllowListReportsBucket"
    effect = "Allow"

    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]

    resources = [var.s3_bucket_arn]
  }

  statement {
    sid    = "AllowReportsObjectOperations"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:AbortMultipartUpload"
    ]

    resources = ["${var.s3_bucket_arn}/*"]
  }
}

resource "aws_iam_policy" "storage_s3" {
  name        = "${var.name_prefix}-storage-s3"
  description = "Allow storage-service to manage SmartFarming reports in S3"
  policy      = data.aws_iam_policy_document.storage_s3.json

  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-storage-s3"
    Service = "irsa"
  })
}

resource "aws_iam_role_policy_attachment" "storage_s3" {
  role       = aws_iam_role.this["storage"].name
  policy_arn = aws_iam_policy.storage_s3.arn
}

data "aws_iam_policy_document" "farm_data_rds" {
  statement {
    sid    = "AllowRDSIAMConnect"
    effect = "Allow"

    actions = ["rds-db:connect"]

    resources = [
      "arn:aws:rds-db:${var.aws_region}:${var.aws_account_id}:dbuser:${var.rds_db_resource_id}/${var.rds_db_username}"
    ]
  }
}

resource "aws_iam_policy" "farm_data_rds" {
  name        = "${var.name_prefix}-farm-data-rds-iam"
  description = "Allow farm-data-service to connect to RDS using IAM auth"
  policy      = data.aws_iam_policy_document.farm_data_rds.json

  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-farm-data-rds-iam"
    Service = "irsa"
  })
}

resource "aws_iam_role_policy_attachment" "farm_data_rds" {
  role       = aws_iam_role.this["farm_data"].name
  policy_arn = aws_iam_policy.farm_data_rds.arn
}
