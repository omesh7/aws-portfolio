# Enable required APIs
resource "google_project_service" "compute" {
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "storage" {
  service            = "storage.googleapis.com"
  disable_on_destroy = false
}

# Cloud Storage bucket for static website
resource "google_storage_bucket" "website" {
  name          = replace(replace(var.domain_name, ".", "-"), "_", "-")
  location      = "US"
  force_destroy = true

  depends_on = [google_project_service.storage]

  website {
    main_page_suffix = "index.html"
    not_found_page   = "error.html"
  }

  uniform_bucket_level_access = true

  labels = {
    environment = "production"
    project     = "weather-tracker"
  }
}

# Make bucket publicly readable
resource "google_storage_bucket_iam_member" "website_public" {
  bucket = google_storage_bucket.website.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

# Cloud CDN backend bucket
resource "google_compute_backend_bucket" "website" {
  name        = "${replace(var.domain_name, ".", "-")}-backend"
  bucket_name = google_storage_bucket.website.name
  enable_cdn  = true

  depends_on = [google_project_service.compute]
}

# URL map for load balancer
resource "google_compute_url_map" "website" {
  name            = "${replace(var.domain_name, ".", "-")}-url-map"
  default_service = google_compute_backend_bucket.website.id

  depends_on = [google_project_service.compute]
}

# SSL certificate
resource "google_compute_managed_ssl_certificate" "website" {
  name = "${replace(var.domain_name, ".", "-")}-ssl-cert"

  managed {
    domains = [var.domain_name]
  }

  depends_on = [google_project_service.compute]
}

# HTTP(S) proxy
resource "google_compute_target_https_proxy" "website" {
  name             = "${replace(var.domain_name, ".", "-")}-https-proxy"
  url_map          = google_compute_url_map.website.id
  ssl_certificates = [google_compute_managed_ssl_certificate.website.id]

  depends_on = [google_project_service.compute]
}

# Global forwarding rule
resource "google_compute_global_forwarding_rule" "website" {
  name       = "${replace(var.domain_name, ".", "-")}-forwarding-rule"
  target     = google_compute_target_https_proxy.website.id
  port_range = "443"

  depends_on = [google_project_service.compute]
}

# HTTP to HTTPS redirect
resource "google_compute_url_map" "https_redirect" {
  name = "${replace(var.domain_name, ".", "-")}-https-redirect"

  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }

  depends_on = [google_project_service.compute]
}

resource "google_compute_target_http_proxy" "https_redirect" {
  name    = "${replace(var.domain_name, ".", "-")}-http-proxy"
  url_map = google_compute_url_map.https_redirect.id

  depends_on = [google_project_service.compute]
}

resource "google_compute_global_forwarding_rule" "https_redirect" {
  name       = "${replace(var.domain_name, ".", "-")}-http-forwarding-rule"
  target     = google_compute_target_http_proxy.https_redirect.id
  port_range = "80"

  depends_on = [google_project_service.compute]
}

# Generate API config file with Lambda URL for GCP
resource "local_file" "gcp_api_config" {
  content  = "window.LAMBDA_API_URL = '${var.lambda_function_url}api/weather';"
  filename = "${path.module}/../../../frontend/config.js"
}

# Upload frontend files to Google Cloud Storage
resource "google_storage_bucket_object" "frontend_files" {
  for_each = fileset("${path.module}/../../../frontend", "**/*")

  bucket = google_storage_bucket.website.name
  name   = each.value
  source = "${path.module}/../../../frontend/${each.value}"
  
  content_type = lookup({
    "html" = "text/html",
    "css"  = "text/css",
    "js"   = "application/javascript",
    "ico"  = "image/x-icon"
  }, split(".", each.value)[length(split(".", each.value)) - 1], "application/octet-stream")

  depends_on = [google_storage_bucket_iam_member.website_public, local_file.gcp_api_config]
}
