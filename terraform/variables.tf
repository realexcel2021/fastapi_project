variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = "fast-api-cluster"
}

variable "service_name" {
  description = "Name of the ECS service"
  type        = string
  default     = "fastapi-svc"
}

variable "container_images" {
  description = "Container images for the services"
  type        = map(string)
  default     = {
    fastapi = "sheriffexcel/waaron-vwr-ui"
    api     = "sheriffexcel/waaron-vwr-api"
  }
}

variable "container_ports" {
  description = "Container ports for the services"
  type        = map(number)
  default     = {
    fastapi = 3000
    api     = 8000
  }
}

variable "api_environment" {
  description = "Environment variables for the API container"
  type = map(string)
  default = {

    DB_USER = "fastapi"
    DB_NAME = "test"
    DB_PORT = "3306"
  }
}

variable "fastapi_environment" {
  description = "Environment variables for the FastAPI container"
  type = map(string)
  default = {
    REACT_APP_API_URL = "http:///3.11.55.236:8000"
  }
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 1
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "container_cpu" {
  description = "CPU units for containers"
  type        = number
  default     = 256
}

variable "container_memory" {
  description = "Memory for containers"
  type        = number
  default     = 512
}

variable "service_cpu" {
  description = "CPU units for the ECS service"
  type        = number
  default     = 512
}

variable "service_memory" {
  description = "Memory for the ECS service"
  type        = number
  default     = 1024
}

variable "container_memory_reservation" {
  description = "Memory reservation for containers"
  type        = number
  default     = 100
}
