output "vpc_id" {
    description = "The ID of the VPC"
    value       = aws_vpc.main_vpc.id
}

output "subnet_az1_id" {
    description = "ID of the subnet in AZ 1"
    value       = aws_subnet.subnet_az1.id
}

output "subnet_az2_id" {
    description = "ID of the subnet in AZ 2"
    value       = aws_subnet.subnet_az2.id
}

output "subnet_az3_id" {
    description = "ID of the subnet in AZ 3"
    value       = aws_subnet.subnet_az3.id
}