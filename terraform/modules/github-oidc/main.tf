locals {
  provider_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : var.existing_oidc_provider_arn
  branch_subjects = [
    for branch in var.allowed_branches : "repo:${var.github_repository}:ref:refs/heads/${branch}"
  ]
  allowed_subjects = concat(local.branch_subjects, var.additional_subjects)
}

resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 1 : 0

  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = var.github_oidc_thumbprints

  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-github-oidc"
    Service = "github-oidc"
  })
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [local.provider_arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.allowed_subjects
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name                 = "${var.name_prefix}-github-actions"
  assume_role_policy   = data.aws_iam_policy_document.assume_role.json
  max_session_duration = 3600

  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-github-actions"
    Service = "github-oidc"
  })
}

data "aws_iam_policy_document" "github_actions" {
  statement {
    sid    = "ECRLogin"
    effect = "Allow"

    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "ECRPushPull"
    effect = "Allow"

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:ListImages",
      "ecr:PutImage",
      "ecr:UploadLayerPart"
    ]

    resources = var.ecr_repository_arns
  }

  statement {
    sid    = "EKSDescribeCluster"
    effect = "Allow"

    actions   = ["eks:DescribeCluster"]
    resources = [var.eks_cluster_arn]
  }

  statement {
    sid    = "STSIdentity"
    effect = "Allow"

    actions   = ["sts:GetCallerIdentity"]
    resources = ["*"]
  }

  dynamic "statement" {
    for_each = var.state_bucket_arn != "" ? [1] : []

    content {
      sid    = "TerraformStateBucketList"
      effect = "Allow"

      actions = ["s3:ListBucket"]

      resources = [var.state_bucket_arn]

      condition {
        test     = "StringLike"
        variable = "s3:prefix"
        values   = ["${var.state_key_prefix}/*"]
      }
    }
  }

  dynamic "statement" {
    for_each = var.state_bucket_arn != "" ? [1] : []

    content {
      sid    = "TerraformStateObjects"
      effect = "Allow"

      actions = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ]

      resources = ["${var.state_bucket_arn}/${var.state_key_prefix}/*"]
    }
  }
}

resource "aws_iam_policy" "github_actions" {
  name        = "${var.name_prefix}-github-actions"
  description = "Allow GitHub Actions to push ECR images and deploy SmartFarming workloads"
  policy      = data.aws_iam_policy_document.github_actions.json

  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-github-actions"
    Service = "github-oidc"
  })
}

resource "aws_iam_role_policy_attachment" "github_actions" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions.arn
}

resource "aws_eks_access_entry" "github_actions" {
  count = var.grant_eks_cluster_admin ? 1 : 0

  cluster_name  = var.eks_cluster_name
  principal_arn = aws_iam_role.github_actions.arn
  type          = "STANDARD"

  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-github-actions"
    Service = "github-oidc"
  })
}

resource "aws_eks_access_policy_association" "github_actions_admin" {
  count = var.grant_eks_cluster_admin ? 1 : 0

  cluster_name  = var.eks_cluster_name
  principal_arn = aws_iam_role.github_actions.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.github_actions]
}
