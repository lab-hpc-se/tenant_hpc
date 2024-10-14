data "aws_region" "selected" {}
data "aws_caller_identity" "current" {}
data "aws_vpc" "selected" {}

data "aws_subnets" "private_subnets" {
    filter {
        name = "vpc-id"
        values = [data.aws_vpc.selected.id]
    }

    tags = {
        "kubernetes.io/role/internal-elb" = 1
    }
}
