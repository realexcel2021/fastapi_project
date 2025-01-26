# Generate random password for RDS
resource "random_password" "rds_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Store the password in Parameter Store
resource "aws_ssm_parameter" "rds_password" {
  name        = "/dev/rds/password"
  description = "RDS master password"
  type        = "SecureString"
  value       = random_password.rds_password.result
}

# Create RDS subnet group
resource "aws_db_subnet_group" "rds" {
  name       = "dev-rds-subnet-group"
  subnet_ids = module.vpc.private_subnets

  tags = {
    Name = "Dev RDS subnet group"
  }
}

# Create RDS security group
resource "aws_security_group" "rds" {
  name        = "dev-rds-sg"
  description = "Security group for RDS instance"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [module.ecs_service.security_group_id, module.ecs_service_api.security_group_id]
    description     = "Allow MySQL access from ECS tasks"
  }

  tags = {
    Name = "dev-rds-sg"
  }
}

# Create RDS instance
resource "aws_db_instance" "dev" {
  identifier        = "dev-mysql"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  db_name  = "test"
  username = "fastapi"
  password = random_password.rds_password.result

  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  skip_final_snapshot     = true
  backup_retention_period = 1
  multi_az               = false

  # Enable automated backups
  backup_window = "03:00-04:00"

  # Maintenance window
  maintenance_window = "Mon:04:00-Mon:05:00"

  # Enable deletion protection
  deletion_protection = false

  # Enable encryption
  storage_encrypted = true

  tags = {
    Environment = "dev"
  }
}

# Store the RDS endpoint in Parameter Store
resource "aws_ssm_parameter" "rds_endpoint" {
  name        = "/dev/rds/endpoint"
  description = "RDS endpoint"
  type        = "String"
  value       = aws_db_instance.dev.address
}
