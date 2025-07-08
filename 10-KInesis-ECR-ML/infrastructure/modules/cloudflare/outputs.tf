# modules/cloudflare/outputs.tf

output "acm_validation" {
  description = "ACM DNS validation record FQDNs"
  value       = cloudflare_record.acm_validation[*]
}
