output "instance_id" {
  value = aws_instance.windows.id
}

output "public_ip" {
  value = aws_instance.windows.public_ip
}
