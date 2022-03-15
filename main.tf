provider "aws" {
  region = "ap-south-1"
  # AWS ACCESS KEY
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

resource "aws_vpc" "custom_vpc" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name = var.vpc_name
  }
}

# PUBLIC SUBNETS
resource "aws_subnet" "public_subnets" {
  count                   = var.public_subnets == null ? 0 : length(var.public_subnets)
  vpc_id                  = aws_vpc.custom_vpc.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.subnets_azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet-${count.index}"
  }
}

# PRIVATE SUBNETS
resource "aws_subnet" "private_subnets" {
  count                   = var.private_subnets == null ? 0 : length(var.private_subnets)
  vpc_id                  = aws_vpc.custom_vpc.id
  cidr_block              = var.private_subnets[count.index]
  availability_zone       = var.subnets_azs[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "private_subnet-${count.index}"
  }
}

# INTERNET GATEWAY
resource "aws_internet_gateway" "i_gateway" {
  vpc_id = aws_vpc.custom_vpc.id

  tags = {
    Name = "i_gateway"
  }
}

# EIPs
resource "aws_eip" "elastic_ip" {
  count      = var.private_subnets == null || var.nat_gateways == false ? 0 : length(var.private_subnets)
  vpc        = true
  depends_on = [aws_internet_gateway.i_gateway]

  tags = {
    Name = "eip-${count.index}"
  }
}

# NAT GATEWAYS
resource "aws_nat_gateway" "nats" {
  count             = var.private_subnets == null || var.nat_gateways == false ? 0 : length(var.private_subnets)
  subnet_id         = aws_subnet.public_subnets[count.index].id
  connectivity_type = "public"
  allocation_id     = aws_eip.elastic_ip[count.index].id
  depends_on        = [aws_internet_gateway.i_gateway]
}

# PUBLIC ROUTE TABLE
resource "aws_route_table" "public_table" {
  vpc_id = aws_vpc.custom_vpc.id
}

resource "aws_route" "public_routes" {
  route_table_id         = aws_route_table.public_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.i_gateway.id
}

resource "aws_route_table_association" "assoc_public_routes" {
  count          = length(var.public_subnets)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_table.id
}

# PRIVATE ROUTE TABLES
resource "aws_route_table" "private_tables" {
  count  = length(var.subnets_azs)
  vpc_id = aws_vpc.custom_vpc.id
}

resource "aws_route" "private_routes" {
  count                  = length(var.private_subnets)
  route_table_id         = aws_route_table.private_tables[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nats[count.index].id
}

resource "aws_route_table_association" "assoc_private_routes" {
  count          = length(var.private_subnets)
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_tables[count.index].id
}

# SECURITY GROUP
resource "aws_security_group" "sec_groups" {
  name        = var.security_group_name
  description = var.security_group_description
  vpc_id      = aws_vpc.custom_vpc.id

  ingress {
    description      = var.ingress_description
    from_port        = var.ingress_from_port
    to_port          = var.ingress_to_port
    protocol         = var.ingress_protocol
    cidr_blocks      = var.ingress_cidr_blocks
    ipv6_cidr_blocks = var.ingress_ipv6_cidr_blocks
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_iam_role" "EKSClusterRole" {
  name = "EKSClusterRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role" "NodeGroupRole" {
  name = "EKSNodeGroupRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.EKSClusterRole.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.NodeGroupRole.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.NodeGroupRole.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.NodeGroupRole.name
}

resource "aws_eks_cluster" "eks-cluster" {
  name     = var.eks_cluster_name
  role_arn = aws_iam_role.EKSClusterRole.arn
  version  = "1.21"

  vpc_config {
    subnet_ids         = flatten([[aws_subnet.public_subnets[*].id], [aws_subnet.private_subnets[*].id]])
    security_group_ids = [aws_security_group.sec_groups.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy
  ]
}

resource "aws_eks_node_group" "node-ec2" {
  cluster_name    = aws_eks_cluster.eks-cluster.name
  node_group_name = "t3_micro-node_group"
  node_role_arn   = aws_iam_role.NodeGroupRole.arn
  subnet_ids      = flatten([aws_subnet.private_subnets[*].id])

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  ami_type       = "AL2_x86_64"
  instance_types = ["t3.micro"]
  capacity_type  = "ON_DEMAND"
  disk_size      = 20

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy
  ]
}
