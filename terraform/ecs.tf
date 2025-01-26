data "aws_ssm_parameter" "rds_password" {
  name = "/dev/rds/password"

  depends_on = [ aws_ssm_parameter.rds_password ]
}

module "ecs_cluster" {
  source = "./modules/ecs_cluster/modules/cluster"

  cluster_name = "fast-api-cluster"

  cluster_configuration = {
    execute_command_configuration = {
      logging = "OVERRIDE"
      log_configuration = {
        cloud_watch_log_group_name = "/aws/ecs/aws-fargate/fast-api-cluster"
      }
    }
  }

  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 50
      }
    }
  }
}

module "ecs_service" {
  source = "./modules/ecs_service/modules/service"
  name        = "fastapi-svc"
  cluster_arn = module.ecs_cluster.arn
  cpu    = 512
  memory = 1024
  container_definitions = {
    fastapi = {
      cpu       = 256
      memory    = 512
      essential = true
      image     = "sheriffexcel/waaron-vwr-ui"
      readonly_root_filesystem = false
      port_mappings = [
        {
          name          = "poet_names"
          containerPort = 3000
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "REACT_APP_API_URL"
          value = "http://${module.api_alb.dns_name}"
        }
      ]
      create_cloudwatch_log_group = false
      log_configuration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "fastapi-container",
          awslogs-region        = "us-east-1",
          awslogs-create-group  = "true",
          awslogs-stream-prefix = "fastapi"
        }
      }
      memory_reservation = 100
    }

    api = {
      cpu       = 256
      memory    = 512
      essential = true
      image     = "sheriffexcel/waaron-vwr-api"
      readonly_root_filesystem = false
      port_mappings = [
        {
          name          = "api"
          containerPort = 8000
          protocol      = "tcp"
        }
      ]
      secrets = [
        {
          name      = "DB_PASSWORD"
          valueFrom = "${data.aws_ssm_parameter.rds_password.arn}"
        }
      ]
      environment = [
        {
          name  = "WAITING_ROOM_API_URL"
          value = local.waiting_room_api_url
        },
        {
          name  = "WAITING_ROOM_EVENT_ID"
          value = local.waiting_room_event_id
        },
        {
          name  = "ISSUER"
          value = local.issuer_url
        },
        {
          name  = "DB_USER"
          value = "fastapi"
        },
        {
          name  = "DB_HOST"
          value = "${aws_db_instance.dev.address}"
        },
        {
          name  = "DB_PORT"
          value = "3306"
        },
        {
          name  = "DB_NAME"
          value = "test"
        }
      ]
      create_cloudwatch_log_group = false
      log_configuration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "api-container",
          awslogs-region        = "us-east-1",
          awslogs-create-group  = "true",
          awslogs-stream-prefix = "api"
        }
      }
      memory_reservation = 100
    }
  }

  load_balancer = {
    service = {
      target_group_arn = module.alb.target_groups["ecs-tasks"].arn
      container_name   = "fastapi"
      container_port   = 3000
    }
  }

  subnet_ids = module.vpc.private_subnets
  security_group_rules = {
    alb_ingress_3000 = {
      type                     = "ingress"
      from_port                = 3000
      to_port                  = 3000
      protocol                 = "tcp"
      description              = "Service port"
      source_security_group_id = module.alb.security_group_id
    }
    alb_ingress_8000 = {
      type                     = "ingress"
      from_port                = 8000
      to_port                  = 8000
      protocol                 = "tcp"
      description              = "API service port"
      source_security_group_id = module.alb.security_group_id
    }

    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}

# API ECS Service
module "ecs_service_api" {
  source = "./modules/ecs_service/modules/service"
  name        = "api-svc"
  cluster_arn = module.ecs_cluster.arn
  cpu    = var.service_cpu
  memory = var.service_memory

  container_definitions = {
    api = {
      cpu       = var.container_cpu
      memory    = var.container_memory
      essential = true
      image     = var.container_images["api"]
      readonly_root_filesystem = false
      port_mappings = [
        {
          name          = "api"
          containerPort = var.container_ports["api"]
          protocol      = "tcp"
        }
      ]
      secrets = [
        {
          name      = "DB_PASSWORD"
          valueFrom = data.aws_ssm_parameter.rds_password.arn
        }
      ]
      environment = [
        {
          name  = "WAITING_ROOM_API_URL"
          value = local.waiting_room_api_url
        },
        {
          name  = "WAITING_ROOM_EVENT_ID"
          value = local.waiting_room_event_id
        },
        {
          name  = "ISSUER"
          value = local.issuer_url
        },
        {
          name  = "DB_USER"
          value = "fastapi"
        },
        {
          name  = "DB_HOST"
          value = aws_db_instance.dev.address
        },
        {
          name  = "DB_PORT"
          value = "3306"
        },
        {
          name  = "DB_NAME"
          value = "test"
        }
      ]
      create_cloudwatch_log_group = false
      log_configuration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "api-container",
          awslogs-region        = var.aws_region,
          awslogs-create-group  = "true",
          awslogs-stream-prefix = "api"
        }
      }
      
    }
  }

  load_balancer = {
    service = {
      target_group_arn = module.api_alb.target_groups["api-tasks"].arn
      container_name   = "api"
      container_port   = 8000
    }
  }

  subnet_ids = module.vpc.private_subnets
  security_group_rules = {
    alb_ingress_8000 = {
      type                     = "ingress"
      from_port                = 8000
      to_port                  = 8000
      protocol                 = "tcp"
      description              = "API service port"
      source_security_group_id = aws_security_group.api_alb.id
    }
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}

resource "aws_cloudwatch_log_group" "fastapi-container" {
  name = "fastapi-container"
  retention_in_days = 1
}

resource "aws_cloudwatch_log_group" "api-container" {
  name              = "api-container"
  retention_in_days = 1
}