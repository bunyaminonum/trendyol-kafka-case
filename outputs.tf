output "kafka_broker_ips" {
    value = module.compute.broker_public_ips
}

output "kafka_controller_ips" {
    value = module.compute.controller_public_ips
}

output "kafka_connect_ip" {
    value = module.compute.connect_public_ip
}

output "kafka_observability_ip" {
    value = module.compute.observability_public_ip
}