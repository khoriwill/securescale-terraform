# SNS Topic for alerts
resource "aws_sns_topic" "alerts" {
  name = "SecureScale-Alerts"

  tags = {
    Name        = "SecureScale-Alerts"
    Environment = var.environment
  }
}

# SNS Email Subscription
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# CloudWatch Alarm — High CPU on EC2
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "SecureScale-High-CPU"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "EC2 CPU above 80% for 4 minutes"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.securescale.name
  }

  tags = {
    Name        = "SecureScale-High-CPU"
    Environment = var.environment
  }
}

# CloudWatch Alarm — ALB Unhealthy Hosts
resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts" {
  alarm_name          = "SecureScale-Unhealthy-Hosts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "One or more targets are unhealthy"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = aws_lb.securescale.arn_suffix
    TargetGroup  = aws_lb_target_group.securescale.arn_suffix
  }

  tags = {
    Name        = "SecureScale-Unhealthy-Hosts"
    Environment = var.environment
  }
}

# CloudWatch Alarm — ALB High Response Time
resource "aws_cloudwatch_metric_alarm" "high_latency" {
  alarm_name          = "SecureScale-High-Latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 1
  alarm_description   = "ALB response time above 1 second"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = aws_lb.securescale.arn_suffix
  }

  tags = {
    Name        = "SecureScale-High-Latency"
    Environment = var.environment
  }
}

# CloudWatch Alarm — ALB 5XX Errors
resource "aws_cloudwatch_metric_alarm" "http_5xx" {
  alarm_name          = "SecureScale-5XX-Errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "More than 10 5XX errors in 1 minute"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.securescale.arn_suffix
  }

  tags = {
    Name        = "SecureScale-5XX-Errors"
    Environment = var.environment
  }
}