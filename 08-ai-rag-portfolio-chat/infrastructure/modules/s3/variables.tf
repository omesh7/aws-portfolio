variable "sku" {
  type        = string
  description = "Unique suffix for resource names"
}



variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
}
