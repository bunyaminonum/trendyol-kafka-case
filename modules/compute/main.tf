# AMI Data Source
# Dynamically fetches the latest Ubuntu 22.04 LTS AMI ID for the region.
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# -------------------------------------------------------------------------
# [A] Kafka Brokers: 4 nodes distributed across AZs (2 in AZ-1, 2 in AZ-2)
# -------------------------------------------------------------------------

# Brokers in AZ-1
resource "aws_instance" "broker_az1" {
  count                  = 2
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.small"
  subnet_id              = var.subnet_az1
  vpc_security_group_ids = [var.security_group]
  key_name               = var.key_name

  tags = {
    Name = "kafka-broker-az1-${count.index + 1}"
    Role = "Broker"
  }
}

# Brokers in AZ-2
resource "aws_instance" "broker_az2" {
  count                  = 2
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.small"
  subnet_id              = var.subnet_az2
  vpc_security_group_ids = [var.security_group]
  key_name               = var.key_name

  tags = {
    Name = "kafka-broker-az2-${count.index + 1}"
    Role = "Broker"
  }
}

# -------------------------------------------------------------------------
# [B] Kafka Controllers: 3 nodes distributed across AZs (1 in AZ-1, 1 in AZ-2, 1 in AZ-3)
# -------------------------------------------------------------------------

resource "aws_instance" "controller_az1" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.small"
  subnet_id              = var.subnet_az1
  vpc_security_group_ids = [var.security_group]
  key_name               = var.key_name

  tags = {
    Name = "kafka-controller-az1"
    Role = "Controller"
  }
}

resource "aws_instance" "controller_az2" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.small"
  subnet_id              = var.subnet_az2
  vpc_security_group_ids = [var.security_group]
  key_name               = var.key_name

  tags = {
    Name = "kafka-controller-az2"
    Role = "Controller"
  }
}

resource "aws_instance" "controller_az3" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.small"
  subnet_id              = var.subnet_az3
  vpc_security_group_ids = [var.security_group]
  key_name               = var.key_name

  tags = {
    Name = "kafka-controller-az3"
    Role = "Controller"
  }
}

# -------------------------------------------------------------------------
# [C] Kafka Connect Cluster: 1 node
# -------------------------------------------------------------------------

resource "aws_instance" "connect" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.small"
  subnet_id              = var.subnet_az1
  vpc_security_group_ids = [var.security_group]
  key_name               = var.key_name

  tags = {
    Name = "kafka-connect"
    Role = "Connect"
  }
}

# -------------------------------------------------------------------------
# [D] Observability: 1 node
# -------------------------------------------------------------------------

resource "aws_instance" "observability" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.medium" # Slightly larger for Grafana/Prometheus
  subnet_id              = var.subnet_az1
  vpc_security_group_ids = [var.security_group]
  key_name               = var.key_name

  tags = {
    Name = "kafka-observability"
    Role = "Observability"
  }
}