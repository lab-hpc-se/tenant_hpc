resource "aws_ecr_repository" "hcp_1_ecr" {
  name                 = "hpc-1-images"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
