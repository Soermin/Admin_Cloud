locals {
  az_count  = length(var.availability_zones)
  nat_count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : local.az_count) : 0

  cluster_discovery_tag = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name    = "${var.name}-vpc"
    Service = "network"
  })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name    = "${var.name}-igw"
    Service = "network"
  })
}

resource "aws_subnet" "public" {
  for_each = {
    for index, az in var.availability_zones : az => {
      cidr  = var.public_subnet_cidrs[index]
      index = index
    }
  }

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.key
  map_public_ip_on_launch = true

  tags = merge(var.tags, local.cluster_discovery_tag, {
    Name                     = "${var.name}-public-${each.value.index + 1}"
    Service                  = "network"
    "kubernetes.io/role/elb" = "1"
  })
}

resource "aws_subnet" "private" {
  for_each = {
    for index, az in var.availability_zones : az => {
      cidr  = var.private_subnet_cidrs[index]
      index = index
    }
  }

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.key

  tags = merge(var.tags, local.cluster_discovery_tag, {
    Name                              = "${var.name}-private-${each.value.index + 1}"
    Service                           = "network"
    "kubernetes.io/role/internal-elb" = "1"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(var.tags, {
    Name    = "${var.name}-public-rt"
    Service = "network"
  })
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat" {
  count = local.nat_count

  domain = "vpc"

  tags = merge(var.tags, {
    Name    = "${var.name}-nat-${count.index + 1}"
    Service = "network"
  })

  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  count = local.nat_count

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = values(aws_subnet.public)[var.single_nat_gateway ? 0 : count.index].id

  tags = merge(var.tags, {
    Name    = "${var.name}-nat-${count.index + 1}"
    Service = "network"
  })

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "private" {
  for_each = aws_subnet.private

  vpc_id = aws_vpc.this.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []

    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.this[var.single_nat_gateway ? 0 : index(var.availability_zones, each.key)].id
    }
  }

  tags = merge(var.tags, {
    Name    = "${var.name}-private-${index(var.availability_zones, each.key) + 1}-rt"
    Service = "network"
  })
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}
