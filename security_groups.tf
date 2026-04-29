# ALB Security Group
resource "aws_security_group" "alb" {
  name        = "SecureScale-ALB-SG"
  description = "Allow HTTP and HTTPS inbound to ALB"
  vpc_id      = aws_vpc.securescale.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "SecureScale-ALB-SG"
    Environment = var.environment
  }
}

# EC2 Security Group
resource "aws_security_group" "ec2" {
  name        = "SecureScale-EC2-SG"
  description = "Allow traffic only from ALB"
  vpc_id      = aws_vpc.securescale.id

  ingress {
    description     = "HTTP from ALB only"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "SecureScale-EC2-SG"
    Environment = var.environment
  }
}