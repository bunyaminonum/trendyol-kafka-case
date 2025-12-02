output "sg_id" {
    description = "The ID of the security group to be used by compute instances"
    value       = aws_security_group.kafka_sg.id
}