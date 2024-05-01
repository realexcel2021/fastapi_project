data "aws_caller_identity" "data" {
}

resource "aws_ecr_repository" "fast_repo" {
  name                 = "fast-api-repo"
  image_tag_mutability = "MUTABLE"
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }
}


