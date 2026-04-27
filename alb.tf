# Application Load Balancer
resource "aws_lb" "securescale" {
  name               = "SecureScale-ALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  tags = {
    Name = "SecureScale-ALB"
  }
}

# Target Group
resource "aws_lb_target_group" "securescale" {
  name     = "SecureScale-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.securescale.id

  health_check {
    enabled             = true
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = {
    Name = "SecureScale-TG"
  }
}

# Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.securescale.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.securescale.arn
  }
}