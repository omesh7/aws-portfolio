variable "project_name" {
  description = "The name of the project, used for naming resources."
  type        = string
  default     = "15-cross-cloud-k8s-gitops"
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "us-central1-a"
}

variable "subnet_cidr" {
  description = "CIDR block for subnet"
  type        = string
  default     = "10.10.0.0/16"
}

variable "cluster_name" {
  description = "Kubernetes cluster name"
  type        = string
  default     = "gcp-k8s-cluster"
}

variable "master_count" {
  description = "Number of master nodes"
  type        = number
  default     = 3
}

variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 3
}

variable "master_machine_type" {
  description = "Machine type for master nodes"
  type        = string
  default     = "e2-medium"
}

variable "worker_machine_type" {
  description = "Machine type for worker nodes"
  type        = string
  default     = "e2-medium"
}

variable "image_family" {
  description = "Image family for instances"
  type        = string
  default     = "ubuntu-2204-lts"
}

variable "public_key_path" {
  description = "Path to public key file"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "domain_name" {
  description = "Domain name for SSL certificate"
  type        = string
  default     = "example.com"
}

variable "labels" {
  description = "Default tags for resources"
  type        = map(string)
  default = {
    Project = "15-cross-cloud-k8s-gitops"
    Owner   = "omesh"
    Environment = "portfolio"
    Description = "Kubernetes Cluster on GCP"
    project-no  = "15"
  }
  
}