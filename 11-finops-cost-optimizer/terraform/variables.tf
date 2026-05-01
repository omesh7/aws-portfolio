variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name used in resource naming"
  type        = string
  default     = "finops-cost-optimizer"
}

variable "scheduler_cron" {
  description = "EventBridge schedule cron expression (UTC). Default: every 5 minutes"
  type        = string
  default     = "cron(0/5 * * * ? *)"
}

variable "alert_email" {
  description = "Email address to receive cost anomaly alerts"
  type        = string
}

variable "cost_anomaly_threshold" {
  description = "Minimum dollar impact to trigger an alert"
  type        = number
  default     = 10
}

variable "cost_anomaly_monitor_type" {
  description = "Cost anomaly monitor type: DIMENSIONAL or CUSTOM"
  type        = string
  default     = "DIMENSIONAL"
}

variable "lambda_runtime" {
  description = "Lambda Python runtime"
  type        = string
  default     = "python3.12"
}

variable "lambda_timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 60
}

variable "lambda_memory" {
  description = "Lambda memory in MB"
  type        = number
  default     = 128
}

variable "dry_run" {
  description = "Set to true to simulate actions without actually stopping/starting instances"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
