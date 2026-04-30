output "alb_dns_name" {
  description = "The DNS name of the load balancer - paste this in your browser"
  value       = aws_lb.securescale.dns_name
}

output "alb_arn" {
  description = "The ARN of the load balancer"
  value       = aws_lb.securescale.arn
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.securescale.id
}

output "public_subnet_ids" {
  description = "The IDs of the public subnets"
  value       = [aws_subnet.public_1.id, aws_subnet.public_2.id]
}

output "asg_name" {
  description = "The name of the Auto Scaling Group"
  value       = aws_autoscaling_group.securescale.name
}
output "rds_endpoint" {
  description = "RDS database endpoint"
  value       = aws_db_instance.securescale.endpoint
  sensitive   = true
}
output "s3_bucket_name" {
  description = "S3 bucket for application assets"
  value       = aws_s3_bucket.app_assets.bucket
}