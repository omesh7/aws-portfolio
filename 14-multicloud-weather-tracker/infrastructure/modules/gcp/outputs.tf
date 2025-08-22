output "storage_bucket_name" {
  description = "Name of the Google Cloud Storage bucket"
  value       = google_storage_bucket.website.name
}

output "cdn_url" {
  description = "Google Cloud CDN URL"
  value       = "https://${google_compute_global_forwarding_rule.website.ip_address}"
}

output "load_balancer_ip" {
  description = "Load balancer IP address"
  value       = google_compute_global_forwarding_rule.website.ip_address
}