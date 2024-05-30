variable "env" {
  description = "Working environment short"
  default     = "dev"
  type        = string
}

variable "aws_region" {
  description = "AWS Region"
  default     = "us-east-1"
  type        = string
}

variable "project" {
  description = "Working project"
  default     = "terraform"
  type        = string
}

variable "environment" {
  description = "Working environment"
  default     = "development"
  type        = string
}

variable "team" {
  description = "Working team"
  default     = "devops"
  type        = string
}

variable "deployedby" {
  description = "Deployed by"
  default     = "terraform"
  type        = string
}

variable "application" {
  description = "Application"
  default     = "automation"
  type        = string
}

variable "email" {
  description = "Owner email"
  default     = "devops@company.io"
  type        = string
}

variable "tenant_id" {
  description = "Azure Tenant ID"
  default     = "be1247cc-5801-4a94-a058-2a2ed07e19d9"
  type        = string
}

variable "dns_zone" {
  description = "DNS Zone"
  type        = map(string)
  default = {
    zone_name = "company.io"
    zone_id   = "8MO8pJPCtC5eXVUKaAK1NB7Fan44NIwE"
  }
}

variable "aws_eks_cluster_name" {
  description = "AWS EKS Cluster Name"
  default     = "dev-eks"
  type        = string
}
