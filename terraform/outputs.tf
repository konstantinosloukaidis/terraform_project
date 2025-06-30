output "public_ips" {
  value = { for k, i in aws_instance.terraform_instance : k => i.public_ip }
}

output "instance_ids" {
  value = [for i in aws_instance.terraform_instance : i.id]
}

output "rds_endpoint" {
  value       = aws_db_instance.postgres.address
}

