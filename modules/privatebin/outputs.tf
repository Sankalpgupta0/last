output "bucket_name" {
  description = "S3 bucket holding the notes."
  value       = aws_s3_bucket.notes.id
}

output "instance_id" {
  description = "EC2 instance id."
  value       = aws_instance.app.id
}

output "public_ip" {
  description = "Public IP (port 3344 is reachable from allowed_cidr only)."
  value       = aws_instance.app.public_ip
}

output "ssm_port_forward_command" {
  description = "Open the app at http://localhost:3344 through Session Manager (no inbound rule needed)."
  value       = "aws ssm start-session --region ${var.region} --target ${aws_instance.app.id} --document-name AWS-StartPortForwardingSession --parameters '{\"portNumber\":[\"${var.app_port}\"],\"localPortNumber\":[\"${var.app_port}\"]}'"
}

output "ssm_shell_command" {
  description = "Admin shell through Session Manager."
  value       = "aws ssm start-session --region ${var.region} --target ${aws_instance.app.id}"
}
