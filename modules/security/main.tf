variable "vpc_id" {
  description = "VPC ID where the security group will be created"
  type        = string
}

# Security Group for Kafka Cluster
# Controls inbound and outbound traffic for all cluster nodes.
resource "aws_security_group" "kafka_sg" {
  name        = "kafka-cluster-sg"
  description = "Security group for Kafka Brokers, Controllers, and Connect workers"
  vpc_id      = var.vpc_id

  # Inbound Rule: SSH Access
  # Allows SSH access for administration (In production, restrict CIDR to VPN/Office IP).
  ingress {
    description = "SSH access from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound Rule: Internal Communication
  # Crucial for Kafka, Zookeeper/KRaft, and JMX communication between nodes.
  # Allows all traffic between instances within this same security group.
  ingress {
    description = "Allow all internal traffic within the security group"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  # Outbound Rule: Internet Access
  # Allows instances to download packages and updates.
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "kafka-security-group"
  }
}
