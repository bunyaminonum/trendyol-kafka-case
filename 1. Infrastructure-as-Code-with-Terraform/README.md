# Infrastructure as Code with Terraform

## Overview

This section provisions the complete AWS infrastructure for the Kafka cluster using Terraform with a modular architecture. The infrastructure is designed for high availability, distributed across 3 availability zones in the `eu-central-1` region.

## Architecture

### Infrastructure Components

- **VPC**: 10.0.0.0/16 CIDR block with DNS hostnames enabled
- **Subnets**: 3 public subnets across availability zones
  - AZ-1 (eu-central-1a): 10.0.1.0/24
  - AZ-2 (eu-central-1b): 10.0.2.0/24
  - AZ-3 (eu-central-1c): 10.0.3.0/24
- **Internet Gateway**: For external connectivity
- **Route Tables**: Public routing for all subnets

### EC2 Instances

| Component | Count | Distribution | Instance Type | Disk |
|-----------|-------|--------------|---------------|------|
| **Kafka Brokers** | 4 | 2 in AZ-1, 2 in AZ-2 | t3.small | 30GB gp3 |
| **Kafka Controllers** | 3 | 1 in AZ-1, 1 in AZ-2, 1 in AZ-3 | t3.small | 30GB gp3 |
| **Kafka Connect** | 1 | AZ-1 | t3.small | 30GB gp3 |
| **Observability** | 1 | AZ-1 | t3.medium | 30GB gp3 |

**Total Instances**: 9 EC2 instances

## Module Structure

```
├── main.tf                    # Root module orchestration
├── outputs.tf                 # Output definitions
├── terraform.tfstate          # State file (generated)
└── modules/
    ├── network/               # VPC, Subnets, IGW, Route Tables
    │   ├── main.tf
    │   ├── outputs.tf
    │   └── variables.tf
    ├── compute/               # EC2 instances
    │   ├── main.tf
    │   ├── outputs.tf
    │   └── variables.tf
    └── security/              # Security Groups
        ├── main.tf
        └── outputs.tf
```

## Prerequisites

- AWS CLI configured with valid credentials
- Terraform >= 1.0
- AWS Key Pair named `kafka-key` created in `eu-central-1` region

## Deployment

### Step 1: Initialize Terraform

```bash
cd "1. Infrastructure-as-Code-with-Terraform"
terraform init
```

### Step 2: Review Infrastructure Plan

```bash
terraform plan
```

### Step 3: Apply Configuration

```bash
terraform apply
```

Type `yes` when prompted to confirm resource creation.

### Step 4: Retrieve Outputs

```bash
terraform output
```

Expected outputs:
- `kafka_broker_ips`: Public IPs of 4 broker nodes
- `kafka_controller_ips`: Public IPs of 3 controller nodes
- `kafka_connect_ip`: Public IP of Kafka Connect node
- `kafka_observability_ip`: Public IP of observability node

## Security Configuration

### Security Group Rules

- **SSH (Port 22)**: Open to 0.0.0.0/0 for administration
- **Internal Communication**: All ports open within security group (self-referencing)
- **Egress**: All outbound traffic allowed

### Production Considerations

⚠️ **Important**: In production environments:
- Restrict SSH access to specific IP ranges (VPN/bastion host)
- Use AWS Systems Manager Session Manager instead of direct SSH
- Implement network segmentation with private subnets
- Enable VPC Flow Logs for network monitoring

## Design Decisions

1. **Multi-AZ Deployment**: Ensures high availability and fault tolerance
2. **Modular Structure**: Separates network, compute, and security concerns for maintainability
3. **Public Subnets**: Simplifies initial setup; production should use private subnets with NAT Gateway
4. **Ubuntu 22.04 LTS**: Latest stable Ubuntu release with long-term support
5. **gp3 EBS Volumes**: Cost-effective with better baseline performance than gp2

## Resource Tagging

All resources are tagged with:
- `Name`: Descriptive resource name
- `Role`: Resource role (Broker, Controller, Connect, etc.)
- `Environment`: Production
- `Project`: DataStreamingCase

## Cleanup

To destroy all provisioned infrastructure:

```bash
terraform destroy
```

Type `yes` when prompted to confirm resource deletion.

## State Management

- State is stored locally in `terraform.tfstate`
- For production, use remote state backend (S3 + DynamoDB)

### Recommended Remote Backend Configuration

```hcl
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "kafka-cluster/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
```

## Troubleshooting

### Issue: Key pair not found
**Solution**: Create an AWS key pair named `kafka-key` in the AWS Console (EC2 → Key Pairs)

### Issue: Insufficient permissions
**Solution**: Ensure your AWS credentials have permissions to create VPC, EC2, and Security Group resources

### Issue: Instance limit exceeded
**Solution**: Request an increase in EC2 instance limits through AWS Service Quotas

## Next Steps

After infrastructure is provisioned:
1. Note down all instance IPs from terraform outputs
2. Proceed to **Section 2: Kafka Cluster Setup and Configuration**
3. Update Ansible inventory with the provisioned IP addresses
