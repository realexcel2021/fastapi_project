output "load_balancer_endpoint" {
  value = module.alb.dns_name
  description = "public endpoint to access the api"
}

output "ecr_repository_url" {
  value = aws_ecr_repository.fast_repo.repository_url
  description = "Repository URL for the fast api image"
}