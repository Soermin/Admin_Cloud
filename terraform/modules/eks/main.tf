data "aws_iam_policy_document" "cluster_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "node_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "cluster" {
  name               = "${var.cluster_name}-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.cluster_assume_role.json

  tags = merge(var.tags, {
    Name    = "${var.cluster_name}-cluster-role"
    Service = "eks"
  })
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "nodes" {
  name               = "${var.cluster_name}-node-role"
  assume_role_policy = data.aws_iam_policy_document.node_assume_role.json

  tags = merge(var.tags, {
    Name    = "${var.cluster_name}-node-role"
    Service = "eks"
  })
}

resource "aws_iam_role_policy_attachment" "worker_node_policy" {
  role       = aws_iam_role.nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "cni_policy" {
  role       = aws_iam_role.nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "ecr_read_only" {
  role       = aws_iam_role.nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_security_group" "cluster" {
  name_prefix = "${var.cluster_name}-cluster-"
  description = "EKS cluster security group"
  vpc_id      = var.vpc_id

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name    = "${var.cluster_name}-cluster-sg"
    Service = "eks"
  })
}

resource "aws_security_group" "nodes" {
  name_prefix = "${var.cluster_name}-nodes-"
  description = "EKS managed node group security group"
  vpc_id      = var.vpc_id

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name    = "${var.cluster_name}-nodes-sg"
    Service = "eks"
  })
}

resource "aws_security_group_rule" "cluster_ingress_nodes_https" {
  type                     = "ingress"
  description              = "Allow worker nodes to reach the Kubernetes API"
  security_group_id        = aws_security_group.cluster.id
  source_security_group_id = aws_security_group.nodes.id
  protocol                 = "tcp"
  from_port                = 443
  to_port                  = 443
}

resource "aws_security_group_rule" "nodes_ingress_self" {
  type              = "ingress"
  description       = "Allow node-to-node traffic"
  security_group_id = aws_security_group.nodes.id
  self              = true
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
}

resource "aws_security_group_rule" "nodes_ingress_cluster_https" {
  type                     = "ingress"
  description              = "Allow control plane HTTPS traffic to nodes"
  security_group_id        = aws_security_group.nodes.id
  source_security_group_id = aws_security_group.cluster.id
  protocol                 = "tcp"
  from_port                = 443
  to_port                  = 443
}

resource "aws_security_group_rule" "nodes_ingress_cluster_kubelet" {
  type                     = "ingress"
  description              = "Allow control plane kubelet traffic to nodes"
  security_group_id        = aws_security_group.nodes.id
  source_security_group_id = aws_security_group.cluster.id
  protocol                 = "tcp"
  from_port                = 10250
  to_port                  = 10250
}

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.cluster_version

  enabled_cluster_log_types = var.enabled_cluster_log_types

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  vpc_config {
    subnet_ids              = var.cluster_subnet_ids
    security_group_ids      = [aws_security_group.cluster.id]
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.public_access_cidrs
  }

  tags = merge(var.tags, {
    Name    = var.cluster_name
    Service = "eks"
  })

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy
  ]
}

resource "aws_launch_template" "nodes" {
  name_prefix            = "${var.node_group_name}-"
  update_default_version = true
  vpc_security_group_ids = [aws_security_group.nodes.id]

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.node_disk_size
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name    = var.node_group_name
      Service = "eks-node"
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(var.tags, {
      Name    = var.node_group_name
      Service = "eks-node"
    })
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.nodes.arn
  subnet_ids      = var.node_subnet_ids

  capacity_type  = var.node_capacity_type
  instance_types = var.node_instance_types
  labels         = var.node_labels

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  update_config {
    max_unavailable = 1
  }

  launch_template {
    id      = aws_launch_template.nodes.id
    version = aws_launch_template.nodes.latest_version
  }

  tags = merge(var.tags, {
    Name    = var.node_group_name
    Service = "eks-node"
  })

  depends_on = [
    aws_iam_role_policy_attachment.worker_node_policy,
    aws_iam_role_policy_attachment.cni_policy,
    aws_iam_role_policy_attachment.ecr_read_only
  ]
}
