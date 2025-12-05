output "broker_public_ips" {
    description = "Public IP addresses of Broker instances"
    value       = concat(aws_instance.broker_az1[*].public_ip, aws_instance.broker_az2[*].public_ip)
}

output "controller_public_ips" {
    description = "Public IP addresses of Controller instances"
    value       = [aws_instance.controller_az1.public_ip, aws_instance.controller_az2.public_ip, aws_instance.controller_az3.public_ip]
}

output "connect_public_ip" {
    description = "Public IP address of the Kafka Connect instance"
    value       = aws_instance.connect.public_ip
}

output "observability_public_ip" {
    description = "Public IP address of the Observability instance"
    value       = aws_instance.observability.public_ip
}