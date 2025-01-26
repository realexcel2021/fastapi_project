provider "aws" {
  region = "us-east-1"
}

# terraform {
#   backend "s3" {
#     bucket = "sample-outputs-090922321"
#     key    = "fastapi/tfstate"
#     region = "us-east-1"
#   }
# }

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  waiting_room_api_url = "https://d1gv7fyivejatk.cloudfront.net"
  waiting_room_event_id = "Sample"
  issuer_url = "https://xg9l9of39f.execute-api.eu-west-2.amazonaws.com/api"
  api_service_name = "api-svc"
  api_alb_name    = "api-alb"
}

# create VPC

module "vpc" {
  source = "./modules/vpc"

  name = "fast-api-vpc"
  cidr = "10.0.0.0/16"

  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false
  single_nat_gateway = true

  tags = {
    Project = "fast-api"
  }
}