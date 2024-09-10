module "hpc_1_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = "hpc-1-vpc"

  cidr = "10.0.0.0/16"
  azs  = slice(data.aws_availability_zones.available.names, 0, 3)

  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  nat_gateway_tags = {
    "ams:rt:ams-monitoring-policy" = "ams-monitored"
  }

  default_security_group_ingress = [
    {
      description = "All traffic from VPC"
      from_port   = "0"
      to_port     = "0"
      protocol    = "-1"
      cidr_blocks = "10.0.0.0/16"
    }
  ]

  default_security_group_egress = [
    {
      from_port   = "0"
      to_port     = "0"
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}





# resource "aws_vpc" "hpc_1_vpc" {
#   cidr_block = "10.0.0.0/16"

#   tags = {
#     Name = "hpc 1 network"
#   }
# }

# resource "aws_internet_gateway" "hpc_1_internet" {
#   vpc_id = aws_vpc.hpc_1_vpc.id

#   tags = {
#     Name = "hpc 1 internet gateway"
#   }
# }

# resource "aws_route_table" "hpc_1_public_route" {
#   vpc_id = aws_vpc.hpc_1_vpc.id

#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.hpc_1_internet.id
#   }

#   tags = {
#     Name = "Public Route Table"
#   }
# }

# resource "aws_subnet" "hpc_1_cluster_a" {
#   vpc_id            = aws_vpc.hpc_1_vpc.id
#   cidr_block        = "10.0.1.0/24"
#   availability_zone = "us-east-1a"
# }

# resource "aws_subnet" "hpc_1_cluster_b" {
#   vpc_id            = aws_vpc.hpc_1_vpc.id
#   cidr_block        = "10.0.2.0/24"
#   availability_zone = "us-east-1b"
# }

# resource "aws_subnet" "hpc_1_cluster_c" {
#   vpc_id            = aws_vpc.hpc_1_vpc.id
#   cidr_block        = "10.0.3.0/24"
#   availability_zone = "us-east-1c"
# }

# # resource "aws_route_table_association" "public_subnet_cluster_a" {
# #   subnet_id      = aws_subnet.hpc_1_cluster_a
# #   route_table_id = aws_route_table.hpc_1_public_route
# # }

# # resource "aws_route_table_association" "public_subnet_cluster_b" {
# #   subnet_id      = aws_subnet.hpc_1_cluster_
# #   route_table_id = aws_route_table.hpc_1_public_route
# # }

# # resource "aws_route_table_association" "public_subnet_cluster_c" {
# #   subnet_id      = aws_subnet.hpc_1_cluster_c
# #   route_table_id = aws_route_table.hpc_1_public_route
# # }

resource "aws_subnet" "hpc_1_queue_a" {
  vpc_id            = module.hpc_1_vpc.vpc_id
  cidr_block        = "10.0.7.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "hpc_1_lustre_a" {
  vpc_id            = module.hpc_1_vpc.vpc_id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "us-east-1a"
}

# resource "aws_subnet" "hpc_1_lustre_b" {
#   vpc_id            = aws_vpc.hpc_1_vpc.id
#   cidr_block        = "10.0.5.0/24"
#   availability_zone = "us-east-1b"
# }

# resource "aws_subnet" "hpc_1_lustre_c" {
#   vpc_id            = aws_vpc.hpc_1_vpc.id
#   cidr_block        = "10.0.6.0/24"
#   availability_zone = "us-east-1c"
# }

resource "aws_security_group" "hpc_1_sg" {
  name        = "allow_traffic"
  description = "Allow all traffic"
  vpc_id      = module.hpc_1_vpc.vpc_id

  ingress {
    description = "All traffic from VPC"
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = [module.hpc_1_vpc.vpc_cidr_block]
  }

  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Allow All"
  }
}

