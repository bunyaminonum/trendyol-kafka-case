variable "subnet_az1" {
    description = "Subnet ID for Availability Zone 1"
    type        = string
}

variable "subnet_az2" {
    description = "Subnet ID for Availability Zone 2"
    type        = string
}

variable "subnet_az3" {
    description = "Subnet ID for Availability Zone 3"
    type        = string
}

variable "security_group" {
    description = "Security Group ID to associate with instances"
    type        = string
}

variable "key_name" {
    description = "Name of the SSH key pair"
    type        = string
    default     = "kafka-key"
}

variable "disk_size" {
    description = "Root disk size in GB"
    type        = number
    default     = 30
}