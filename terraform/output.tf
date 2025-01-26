output "load_balancer_endpoint" {
  value = module.alb.dns_name
  description = "public endpoint to access the api"
}

