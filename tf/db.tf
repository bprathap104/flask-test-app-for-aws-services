# Define the provider
provider "aws" {
  region = "us-east-1"
}

# Data source for the available AZ's in the region
data "aws_availability_zones" "available" {
  state = "available"
}

# Define the VPC where the RDS cluster will be deployed
data "aws_vpc" "selected" {
  id = "vpc-0d3248ec285276864" # Replace with your VPC ID
}

# Data source for the private subnets
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
}

# Define the subnet group for the RDS cluster
resource "aws_db_subnet_group" "aurora_subnet_group" {
  name        = "aurora-subnet-group-1"
  description = "Subnet group for Aurora MySQL cluster"
  subnet_ids  = data.aws_subnets.private.ids
}

# Define the security group for the RDS cluster
resource "aws_security_group" "aurora_security_group" {
  name_prefix = "aurora-sg-"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_server_sg.id]
  }
}
# Define the web server security group
resource "aws_security_group" "web_server_sg" {
  name_prefix = "web-server-sg-"
  vpc_id      = data.aws_vpc.selected.id
  ingress {
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

data "aws_rds_engine_version" "test" {
  engine             = "aurora-mysql"
  version = "8.0.mysql_aurora.3.06.0"
}
# Define the Aurora MySQL cluster
resource "aws_rds_cluster" "aurora_cluster" {
  cluster_identifier      = "aurora-mysql-cluster"
  engine                  = "aurora-mysql"
  engine_version          = data.aws_rds_engine_version.test.id
  engine_mode             = "provisioned"
  availability_zones      = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1]]
  database_name           = "postgres"
  master_username         = "postgres"
  master_password         = "postgres"
  backup_retention_period = 5
  preferred_backup_window = "07:00-09:00"
  db_subnet_group_name    = aws_db_subnet_group.aurora_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.aurora_security_group.id]
  skip_final_snapshot     = true
}

# Define the Aurora MySQL instance
resource "aws_rds_cluster_instance" "aurora_instance" {
  identifier           = "aurora-mysql-instance"
  cluster_identifier   = aws_rds_cluster.aurora_cluster.id
  instance_class       = "db.t3.medium"
  engine               = aws_rds_cluster.aurora_cluster.engine
  engine_version       = aws_rds_cluster.aurora_cluster.engine_version
  db_subnet_group_name = aws_db_subnet_group.aurora_subnet_group.name
  publicly_accessible  = true
}

