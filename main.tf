resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.name}-vpc"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.name}-igw"
  }
}

locals {
  azs = var.availability_zones
}

resource "aws_subnet" "public" {
  for_each          = { for idx, az in local.azs : idx => {
    az   = az
    cidr = var.public_subnet_cidrs[idx]
  } }
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = {
    Name                                    = "${var.name}-public-${each.value.az}"
    "kubernetes.io/role/elb"               = "1"
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "owned"
  }
}

resource "aws_subnet" "private" {
  for_each          = { for idx, az in local.azs : idx => {
    az   = az
    cidr = var.private_subnet_cidrs[idx]
  } }
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = {
    Name                                            = "${var.name}-private-${each.value.az}"
    "kubernetes.io/role/internal-elb"              = "1"
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "owned"
  }
}

# One NAT GW in the first public subnet
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.name}-nat"
  }
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = values(aws_subnet.public)[0].id

  tags = {
    Name = "${var.name}-nat"
  }

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = {
    Name = "${var.name}-private-rt"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

resource "aws_vpc_endpoint" "s3" {
  count              = var.create_gateway_endpoints ? 1 : 0
  vpc_id             = aws_vpc.this.id
  service_name       = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type  = "Gateway"
  route_table_ids    = [aws_route_table.private.id, aws_route_table.public.id]

  tags = {
    Name = "${var.eks_cluster_name}-s3-endpoint"
  }
}

resource "aws_vpc_endpoint" "dynamodb" {
  count              = var.create_gateway_endpoints ? 1 : 0
  vpc_id             = aws_vpc.this.id
  service_name       = "com.amazonaws.${var.region}.dynamodb"
  vpc_endpoint_type  = "Gateway"
  route_table_ids    = [aws_route_table.private.id, aws_route_table.public.id]

  tags = {
    Name = "${var.eks_cluster_name}-dynamodb-endpoint"
  }
}

