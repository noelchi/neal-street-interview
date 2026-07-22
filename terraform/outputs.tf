output "alb_dns_name" {
  description = "Public DNS name for the Application Load Balancer."
  value       = aws_lb.web.dns_name
}

output "health_url" {
  description = "Public health endpoint URL."
  value       = "http://${aws_lb.web.dns_name}/health"
}

output "autoscaling_group_name" {
  description = "Name of the web Auto Scaling Group."
  value       = aws_autoscaling_group.web.name
}

output "instance_role_name" {
  description = "IAM role attached to web instances."
  value       = aws_iam_role.web.name
}

output "ansible_ssm_bucket_name" {
  description = "S3 bucket used by Ansible's aws_ssm connection for module transfer."
  value       = aws_s3_bucket.ansible_ssm.bucket
}
