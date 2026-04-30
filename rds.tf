# Security Group for RDS
resource "aws_security_group" "rds" {
  name        = "SecureScale-RDS-SG"
  description = "Allow MySQL access from EC2 only"
  vpc_id      = aws_vpc.securescale.id

  ingress {
    description     = "MySQL from EC2 only"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "SecureScale-RDS-SG"
    Environment = var.environment
  }
}

# RDS Subnet Group - uses private subnets
resource "aws_db_subnet_group" "securescale" {
  name       = "securescale-db-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]

  tags = {
    Name        = "SecureScale-DB-Subnet-Group"
    Environment = var.environment
  }
}

# RDS MySQL Instance
resource "aws_db_instance" "securescale" {
  identifier        = "securescale-db"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp2"

  db_name  = "securescale"
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.securescale.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  publicly_accessible = false
  skip_final_snapshot = true
  deletion_protection = false

  backup_retention_period = 0
  backup_window          = "03:00-04:00"
  maintenance_window     = "Mon:04:00-Mon:05:00"

  tags = {
    Name        = "SecureScale-DB"
    Environment = var.environment
  }
}