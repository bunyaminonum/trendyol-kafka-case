# Provider Configuration
# Specifies the cloud provider and region.
provider "aws" {
    region = "eu-central-1"
}

# Module: Network
# Deploys VPC, Subnets, and Route Tables.
module "network" {
    source = "./modules/network"
}

# Module: Security
# Deploys Security Groups and firewall rules.
module "security" {
    source = "./modules/security"
    vpc_id = module.network.vpc_id
}

# Module: Compute
# Deploys EC2 instances for Brokers, Controllers, Connect, and Observability.
module "compute" {
    source         = "./modules/compute"
    subnet_az1     = module.network.subnet_az1_id
    subnet_az2     = module.network.subnet_az2_id
    subnet_az3     = module.network.subnet_az3_id
    security_group = module.security.sg_id
    key_name       = "kafka-key" # Ensure this key pair exists in AWS console
    disk_size      = 30
}