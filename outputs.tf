output "bucket_name" {
  description = "S3 bucket holding the notes."
  value       = module.privatebin.bucket_name
}

output "instance_id" {
  description = "EC2 instance id."
  value       = module.privatebin.instance_id
}

output "public_ip" {
  description = "Public IP (port 3344 is reachable from allowed_cidr only)."
  value       = module.privatebin.public_ip
}

output "ssm_port_forward_command" {
  description = "Open the app at http://localhost:3344 through Session Manager."
  value       = module.privatebin.ssm_port_forward_command
}

output "ssm_shell_command" {
  description = "Admin shell through Session Manager."
  value       = module.privatebin.ssm_shell_command
}
