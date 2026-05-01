terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.49.0"
    }
  }
  backend "gcs" {
    bucket = "terraform-state-gcp-123v4"
    prefix = "terraform/gcp-portfolio/15-cross-cloud-k8s-gitops"
  }
}


provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone

  default_labels = {
    for key, value in var.labels : key => value
  }
}

# VPC Network
resource "google_compute_network" "k8s_network" {
  name                    = "${var.project_name}-k8s-network"
  auto_create_subnetworks = false
}

# Subnet
resource "google_compute_subnetwork" "k8s_subnet" {
  name          = "${var.project_name}-k8s-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.k8s_network.id

  secondary_ip_range {
    range_name    = "k8s-pods"
    ip_cidr_range = "10.1.0.0/16"
  }

  secondary_ip_range {
    range_name    = "k8s-services"
    ip_cidr_range = "10.2.0.0/16"
  }
}

# Firewall Rules
resource "google_compute_firewall" "k8s_internal" {
  name    = "${var.project_name}-k8s-internal"
  network = google_compute_network.k8s_network.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.subnet_cidr, "10.1.0.0/16", "10.2.0.0/16"]
  target_tags   = ["k8s-node"]
}

resource "google_compute_firewall" "k8s_external" {
  name    = "${var.project_name}-k8s-external"
  network = google_compute_network.k8s_network.name

  allow {
    protocol = "tcp"
    ports    = ["22", "6443", "30000-32767"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["k8s-node"]
}

# Service Account
resource "google_service_account" "k8s_node_sa" {
  account_id   = "k8s-crosscloud-node"
  display_name = "Kubernetes Node Service Account"
}

resource "google_project_iam_member" "k8s_node_sa_roles" {
  for_each = toset([
    "roles/compute.viewer",
    "roles/storage.objectViewer",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter"
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.k8s_node_sa.email}"
}

# Master Nodes
resource "google_compute_instance" "k8s_masters" {
  count        = var.master_count
  name         = "${var.project_name}-k8s-master-${count.index + 1}"
  machine_type = var.master_machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.image_family
      size  = 20
      type  = "pd-ssd"
    }
  }

  network_interface {
    network    = google_compute_network.k8s_network.name
    subnetwork = google_compute_subnetwork.k8s_subnet.name
    access_config {
      // Ephemeral public IP
    }
  }

  service_account {
    email  = google_service_account.k8s_node_sa.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }

  metadata_startup_script = templatefile("${path.module}/startup-script.sh", {
    node_type = "master"
  })

  tags = ["k8s-node", "k8s-master"]

  labels = {
    role = "master"
    cluster = var.cluster_name
  }
}

# Worker Nodes
resource "google_compute_instance" "k8s_workers" {
  count        = var.worker_count
  name         = "${var.project_name}-k8s-worker-${count.index + 1}"
  machine_type = var.worker_machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.image_family
      size  = 30
      type  = "pd-ssd"
    }
  }

  network_interface {
    network    = google_compute_network.k8s_network.name
    subnetwork = google_compute_subnetwork.k8s_subnet.name
    access_config {
      // Ephemeral public IP
    }
  }

  service_account {
    email  = google_service_account.k8s_node_sa.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }

  metadata_startup_script = templatefile("${path.module}/startup-script.sh", {
    node_type = "worker"
  })

  tags = ["k8s-node", "k8s-worker"]

  labels = {
    role = "worker"
    cluster = var.cluster_name
  }
}

# Load Balancer for API Server
resource "google_compute_global_address" "k8s_api_ip" {
  name = "${var.project_name}-k8s-api-ip"
}

resource "google_compute_health_check" "k8s_api_health" {
  name = "${var.project_name}-k8s-api-health"

  https_health_check {
    port         = 6443
    request_path = "/healthz"
  }

  check_interval_sec  = 30
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3
}

resource "google_compute_instance_group" "k8s_masters_ig" {
  name = "${var.project_name}-k8s-masters-ig"
  zone = var.zone

  instances = google_compute_instance.k8s_masters[*].id

  named_port {
    name = "k8s-api"
    port = 6443
  }
}

resource "google_compute_backend_service" "k8s_api_backend" {
  name                  = "${var.project_name}-k8s-api-backend"
  protocol              = "HTTPS"
  port_name             = "k8s-api"
  load_balancing_scheme = "EXTERNAL"
  health_checks         = [google_compute_health_check.k8s_api_health.id]

  backend {
    group = google_compute_instance_group.k8s_masters_ig.id
  }
}

resource "google_compute_url_map" "k8s_api_url_map" {
  name            = "${var.project_name}-k8s-api-url-map"
  default_service = google_compute_backend_service.k8s_api_backend.id
}

resource "google_compute_target_https_proxy" "k8s_api_proxy" {
  name    = "${var.project_name}-k8s-api-proxy"
  url_map = google_compute_url_map.k8s_api_url_map.id
  ssl_certificates = [google_compute_managed_ssl_certificate.k8s_api_cert.id]
}

resource "google_compute_managed_ssl_certificate" "k8s_api_cert" {
  name = "${var.project_name}-k8s-api-cert"

  managed {
    domains = ["${var.cluster_name}.${var.domain_name}"]
  }
}

resource "google_compute_global_forwarding_rule" "k8s_api_forwarding_rule" {
  name       = "${var.project_name}-k8s-api-forwarding-rule"
  target     = google_compute_target_https_proxy.k8s_api_proxy.id
  port_range = "443"
  ip_address = google_compute_global_address.k8s_api_ip.address
}