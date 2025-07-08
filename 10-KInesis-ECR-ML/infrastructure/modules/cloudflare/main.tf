

resource "cloudflare_record" "acm_validation" {
  count   = length(var.acm_certificate.domain_validation_options)
  zone_id = var.cloudflare_zone_id
  name    = var.acm_certificate.domain_validation_options[count.index].resource_record_name
  type    = var.acm_certificate.domain_validation_options[count.index].resource_record_type
  value   = var.acm_certificate.domain_validation_options[count.index].resource_record_value
  ttl     = 60
}
