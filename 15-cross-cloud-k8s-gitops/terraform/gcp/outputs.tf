output "network_name" {
  description = "Name of the VPC network"
  value       = google_compute_network.k8s_network.name
}

output "subnet_name" {
  description = "Name of the subnet"
  value       = google_compute_subnetwork.k8s_subnet.name
}

output "master_ips" {
  description = "Public IP addresses of master nodes"
  value       = google_compute_instance.k8s_masters[*].network_interface[0].access_config[0].nat_ip
}

output "worker_ips" {
  description = "Public IP addresses of worker nodes"
  value       = google_compute_instance.k8s_workers[*].network_interface[0].access_config[0].nat_ip
}

output "master_private_ips" {
  description = "Private IP addresses of master nodes"
  value       = google_compute_instance.k8s_masters[*].network_interface[0].network_ip
}

output "worker_private_ips" {
  description = "Private IP addresses of worker nodes"
  value       = google_compute_instance.k8s_workers[*].network_interface[0].network_ip
}

output "api_server_ip" {
  description = "Global IP address for API server"
  value       = google_compute_global_address.k8s_api_ip.address
}

output "bastion_ip" {
  description = "Bastion host IP (first master)"
  value       = google_compute_instance.k8s_masters[0].network_interface[0].access_config[0].nat_ip
}