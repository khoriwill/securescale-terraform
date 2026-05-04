resource "aws_cloudwatch_dashboard" "securescale" {
  dashboard_name = "SecureScale-Infrastructure"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "EC2 CPU Utilization"
          view   = "timeSeries"
          region = "us-east-1"
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", aws_autoscaling_group.securescale.name]
          ]
          period = 300
          stat   = "Average"
          yAxis = {
            left = { min = 0, max = 100 }
          }
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "ALB Response Time"
          view   = "timeSeries"
          region = "us-east-1"
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", aws_lb.securescale.arn_suffix]
          ]
          period = 300
          stat   = "Average"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "Unhealthy Host Count"
          view   = "timeSeries"
          region = "us-east-1"
          metrics = [
            ["AWS/ApplicationELB", "UnHealthyHostCount", "LoadBalancer", aws_lb.securescale.arn_suffix, "TargetGroup", aws_lb_target_group.securescale.arn_suffix]
          ]
          period = 60
          stat   = "Maximum"
          yAxis = {
            left = { min = 0 }
          }
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "HTTP 5XX Errors"
          view   = "timeSeries"
          region = "us-east-1"
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", aws_lb.securescale.arn_suffix]
          ]
          period = 60
          stat   = "Sum"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6
        properties = {
          title  = "ALB Request Count"
          view   = "timeSeries"
          region = "us-east-1"
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.securescale.arn_suffix]
          ]
          period = 300
          stat   = "Sum"
        }
      },
      {
        type   = "alarm"
        x      = 12
        y      = 12
        width  = 12
        height = 6
        properties = {
          title  = "Alarm Status"
          alarms = [
            aws_cloudwatch_metric_alarm.high_cpu.arn,
            aws_cloudwatch_metric_alarm.unhealthy_hosts.arn,
            aws_cloudwatch_metric_alarm.high_latency.arn,
            aws_cloudwatch_metric_alarm.http_5xx.arn
          ]
        }
      }
    ]
  })
}

output "dashboard_url" {
  description = "CloudWatch Dashboard URL"
  value       = "https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=SecureScale-Infrastructure"
}