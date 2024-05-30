terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.16"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.1"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.50.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.103.1"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.11.1"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      "Project"     = var.project,
      "Environment" = var.environment,
      "Team"        = var.team,
      "Deployedby"  = var.deployedby,
      "Application" = var.application,
      "OwnerEmail"  = var.email
    }
  }
}

data "aws_eks_cluster" "eks" {
  name = var.aws_eks_cluster_name
}

data "aws_eks_cluster_auth" "eks" {
  name = var.aws_eks_cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.eks.token
  }
}

provider "azurerm" {
  features {}
}

provider "azuread" {
  tenant_id = var.tenant_id
}
