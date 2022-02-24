variable "cluster_name" {
  description = "EKS Cluster name"
  type        = string
}
variable "customer_name" {
  description = "customer name"
  type        = string
}

variable "cluster_oidc_issuer_url" {
  description = "URL of the OIDC Provider from the EKS cluster"
  type        = string
}

variable "service_account_namespace" {
  description = "Namespace of ServiceAccount for thanos"
  default     = "logging"
}

variable "service_account_name" {
  description = "ServiceAccount name for thanos"
  default     = "loki"
}
variable "tags" {
  description = "AWS tags to apply to resources"
  type        = any
  default     = {}
}

variable "account_id" {
  description = "account id aws name"
  type        = string
}

variable "region" {
  description = "region name"
  type        = string
}