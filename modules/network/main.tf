# Core VPC Configuration
# Establishes the virtual network environment for the Kafka cluster.
resource "aws_vpc" "main_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  
  tags = {
    Name        = "kafka-cluster-vpc"
    Environment = "Production"
    Project     = "DataStreamingCase"
  }
}

# Internet Gateway
# Allows communication between instances in the VPC and the internet.
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "kafka-cluster-igw"
  }
}

# Public Subnets configuration across multiple Availability Zones
# Designed to support High Availability (HA) requirements.

# Subnet for Availability Zone 1
resource "aws_subnet" "subnet_az1" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true # Auto-assign public IP for management access

  tags = {
    Name = "kafka-subnet-az1"
  }
}

# Subnet for Availability Zone 2
resource "aws_subnet" "subnet_az2" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-central-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "kafka-subnet-az2"
  }
}

# Subnet for Availability Zone 3 (Required for Controller distribution)
resource "aws_subnet" "subnet_az3" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "eu-central-1c"
  map_public_ip_on_launch = true

  tags = {
    Name = "kafka-subnet-az3"
  }
}

# Route Table Configuration
# Routes traffic from subnets to the Internet Gateway.
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "kafka-public-rt"
  }
}

# Route Table Associations
# Links the subnets to the public route table.
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet_az1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.subnet_az2.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "c" {
  subnet_id      = aws_subnet.subnet_az3.id
  route_table_id = aws_route_table.public_rt.id
}
