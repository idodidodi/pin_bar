output "instance_id" {
  value = aws_instance.t3_micro.id
}

output "public_ip" {
  value = aws_instance.t3_micro.public_ip
}
