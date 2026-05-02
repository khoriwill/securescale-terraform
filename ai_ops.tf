# Zip the Lambda function
data "archive_file" "ai_ops_lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda/ai_ops_advisor.py"
  output_path = "${path.module}/lambda/ai_ops_advisor.zip"
}

# S3 bucket for AI reports
resource "aws_s3_bucket" "ai_reports" {
  bucket        = "securescale-ai-reports-${var.account_id}"
  force_destroy = true

  tags = {
    Name        = "SecureScale-AI-Reports"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_public_access_block" "ai_reports" {
  bucket                  = aws_s3_bucket.ai_reports.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# IAM Role for Lambda
resource "aws_iam_role" "ai_ops_lambda" {
  name = "SecureScale-AI-Ops-Lambda-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = {
    Name        = "SecureScale-AI-Ops-Lambda-Role"
    Environment = var.environment
  }
}

# IAM Policy for Lambda
resource "aws_iam_role_policy" "ai_ops_lambda" {
  name = "SecureScale-AI-Ops-Policy"
  role = aws_iam_role.ai_ops_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.ai_reports.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.alerts.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# Lambda Function
resource "aws_lambda_function" "ai_ops_advisor" {
  filename         = data.archive_file.ai_ops_lambda.output_path
  function_name    = "SecureScale-AI-Ops-Advisor"
  role             = aws_iam_role.ai_ops_lambda.arn
  handler          = "ai_ops_advisor.lambda_handler"
  runtime          = "python3.12"
  timeout          = 120
  source_code_hash = data.archive_file.ai_ops_lambda.output_base64sha256

  environment {
    variables = {
      ASG_NAME       = aws_autoscaling_group.securescale.name
      ALB_ARN_SUFFIX = aws_lb.securescale.arn_suffix
      TG_ARN_SUFFIX  = aws_lb_target_group.securescale.arn_suffix
      REPORT_BUCKET  = aws_s3_bucket.ai_reports.bucket
      SNS_TOPIC_ARN  = aws_sns_topic.alerts.arn
    }
  }

  tags = {
    Name        = "SecureScale-AI-Ops-Advisor"
    Environment = var.environment
  }
}

# EventBridge rule — runs every 6 hours
resource "aws_cloudwatch_event_rule" "ai_ops_schedule" {
  name                = "SecureScale-AI-Ops-Schedule"
  description         = "Triggers AI Ops Advisor every 6 hours"
  schedule_expression = "rate(6 hours)"

  tags = {
    Name        = "SecureScale-AI-Ops-Schedule"
    Environment = var.environment
  }
}

# EventBridge target — Lambda
resource "aws_cloudwatch_event_target" "ai_ops_lambda" {
  rule      = aws_cloudwatch_event_rule.ai_ops_schedule.name
  target_id = "SecureScaleAIOpsAdvisor"
  arn       = aws_lambda_function.ai_ops_advisor.arn
}

# Permission for EventBridge to invoke Lambda
resource "aws_lambda_permission" "ai_ops_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ai_ops_advisor.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ai_ops_schedule.arn
}