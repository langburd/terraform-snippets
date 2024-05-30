# ArgoCD and Argo Workflows Terraform Module

This folder contains the Terraform code for deploying and managing ArgoCD and Argo Workflows on a Kubernetes cluster.

## Overview

The Terraform code in this module is responsible for:

- Creating a Kubernetes namespaces for ArgoCD and Argo Workflows using the [`kubernetes_namespace_v1`](argocd/main.tf) resource.
- Deploying ArgoCD using the [`helm_release`](argocd/main.tf) resource.
- Deploying Argo Workflows using the [`helm_release`](argocd/main.tf) resource.
- Creating an Azure AD application and service principal for ArgoCD using the [`azuread_application`](argocd/main.tf) and [`azuread_service_principal`](argocd/main.tf) resources.
- Creating a Cloudflare DNS record for ArgoCD using the [`cloudflare_record`](argocd/main.tf) resource.
- Fetching the ALB hostname for the ArgoCD server ingress using the [`kubernetes_ingress_v1`](argocd/main.tf) data source.

## Usage

To use this module, you need to provide values for the variables defined in the [`variables.tf`](argocd/variables.tf) file. These include the environment, AWS region, project, team, application, and others.

The Helm values for the ArgoCD and Argo Workflows deployments are defined in the [`argo-cd.yaml`](argocd/helm-values/argo-cd.yaml) and [`argo-workflows.yaml`](argocd/helm-values/argo-workflows.yaml) files in the `helm-values` directory.

## Outputs

The URL of the deployed ArgoCD instance is output by the [`argocd_url`](argocd/outputs.tf) output variable.

## Dependencies

This module depends on the Azure and Cloudflare Terraform providers, as defined in the [`providers.tf`](argocd/providers.tf) file.
