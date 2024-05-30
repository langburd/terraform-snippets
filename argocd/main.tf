# This code creates an Azure AD application and service principal for ArgoCD in the EKS cluster.
data "azurerm_client_config" "main" {}

resource "azuread_application" "argocd" {
  display_name            = "${var.env}-${var.application}-eks-argocd"
  description             = "ArgoCD in '${var.env}-${var.application}-eks'"
  logo_image              = filebase64("${path.module}/files/argocd-logo.png")
  group_membership_claims = ["All"]
  feature_tags {
    custom_single_sign_on = true
    enterprise            = true
  }
  owners = [
    data.azurerm_client_config.main.object_id
  ]
  identifier_uris = [
    "https://${local.argocd_fqdn}/api/dex/callback"
  ]
  web {
    redirect_uris = [
      "https://${local.argocd_fqdn}/api/dex/callback",
    ]
    implicit_grant {
      access_token_issuance_enabled = false
      id_token_issuance_enabled     = false
    }
  }
  optional_claims {
    saml2_token {
      essential             = true
      name                  = "email"
      additional_properties = ["sam_account_name"]
    }
  }
}

resource "azuread_service_principal" "argocd" {
  client_id                     = azuread_application.argocd.client_id
  description                   = "Service Principal for ArgoCD in '${var.env}-${var.application}-eks'"
  owners                        = azuread_application.argocd.owners
  preferred_single_sign_on_mode = "saml"
  login_url                     = "https://${local.argocd_fqdn}/auth/login"
  feature_tags {
    custom_single_sign_on = true
    enterprise            = true
  }
  saml_single_sign_on {
    relay_state = "https://${local.argocd_fqdn}/api/dex/callback"
  }
  notification_email_addresses = [var.email]
}

resource "time_rotating" "argocd" {
  rotation_years = 3
}

resource "azuread_service_principal_token_signing_certificate" "argocd" {
  service_principal_id = azuread_service_principal.argocd.id
  display_name         = "CN=${local.argocd_fqdn}"
  end_date             = time_rotating.argocd.rotation_rfc3339
}

locals {
  binary_cert_base64  = azuread_service_principal_token_signing_certificate.argocd.value
  pem_cert_lines      = [for i in range(0, length(local.binary_cert_base64), 64) : substr(local.binary_cert_base64, i, 64)]
  pem_cert_body       = join("\n", local.pem_cert_lines)
  azure_saml_pem_cert = <<-EOT
  -----BEGIN CERTIFICATE-----
  ${local.pem_cert_body}
  -----END CERTIFICATE-----
  EOT
}

# ArgoCD namespace
resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = "argocd"
  }
}

# Argo CD
locals {
  argocd_fqdn  = "argocd-${var.env}-${var.application}.${var.dns_zone["zone_name"]}"
  argowfs_fqdn = "argowfs-${var.env}-${var.application}.${var.dns_zone["zone_name"]}"
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "6.7.18"
  namespace  = "argocd"
  values = [
    templatefile("${path.module}/helm-values/argo-cd.yaml", {
      alb_certificate_arn                = "arn:aws:acm:us-east-1:123456789101:certificate/b40e11b1-8c53-4d3a-acfc-b4b2fa5173ce"
      alb_group_name                     = "${var.env}-${var.application}-ingress"
      alb_name                           = "${var.env}-${var.application}-eks-alb"
      alb_tags                           = "Environment=${var.env},Team=${var.team},Application=${var.application},DeployedBy=${var.deployedby}"
      argocd_fqdn                        = local.argocd_fqdn
      argowfs_fqdn                       = local.argowfs_fqdn
      argowfs_sso_secret                 = "argowfs-sso-secret"
      azure_client_id                    = azuread_application.argocd.client_id
      azure_saml_ca_data                 = base64encode(trimspace(local.azure_saml_pem_cert))
      azure_tenant_id                    = var.tenant_id
      controller_replicas                = 1
      controller_resources_limits_cpu    = 1
      controller_resources_limits_mem    = "2Gi"
      controller_resources_requests_cpu  = "500m"
      controller_resources_requests_mem  = "1Gi"
      env                                = var.env
      repo_server_max_replicas           = 5
      repo_server_min_replicas           = 1
      repo_server_resources_limits_cpu   = 1
      repo_server_resources_limits_mem   = "2Gi"
      repo_server_resources_requests_cpu = "500m"
      repo_server_resources_requests_mem = "1Gi"
      server_max_replicas                = 5
      server_min_replicas                = 1
      server_resources_limits_cpu        = 1
      server_resources_limits_mem        = "2Gi"
      server_resources_requests_cpu      = "500m"
      server_resources_requests_mem      = "1Gi"
    })
  ]
  depends_on = [
    kubernetes_namespace_v1.argocd,
  ]
}

# Argo Workflows
resource "random_password" "argowfs_sso" {
  length  = 40
  special = true
}

locals {
  argowfs_sso = {
    client-id     = "argowfs-sso"
    client-secret = random_password.argowfs_sso.result
  }
}

# Create the secret for Argo Workflows SSO
resource "aws_secretsmanager_secret" "argowfs_sso" {
  name        = "${var.env}-${var.application}-argowfs-sso"
  description = "Argo Workflows SSO"
}

resource "aws_secretsmanager_secret_version" "argowfs_sso" {
  secret_id     = aws_secretsmanager_secret.argowfs_sso.id
  secret_string = jsonencode(local.argowfs_sso)
}


resource "kubernetes_namespace_v1" "argo_workflows" {
  metadata {
    name = "argo-workflows"
  }
}

resource "helm_release" "argo_workflows" {
  name       = "argo-workflows"
  repository = "https://argoproj.github.io/argo-helm"
  namespace  = "argo-workflows"
  chart      = "argo-workflows"
  version    = "0.41.6"
  values = [
    templatefile("${path.module}/helm-values/argo-workflows.yaml", {
      alb_certificate_arn               = "arn:aws:acm:us-east-1:123456789101:certificate/0a51ec77-6655-48ea-97ea-b1133461f5aa"
      alb_group_name                    = "${var.env}-${var.application}-ingress"
      alb_name                          = "${var.env}-${var.application}-eks-alb"
      alb_tags                          = "Environment=${var.env},Team=${var.team},Application=${var.application},DeployedBy=${var.deployedby}"
      argowfs_fqdn                      = local.argowfs_fqdn
      argowfs_sso                       = "argowfs-sso-secret"
      controller_replicas               = "1"
      controller_resources_limits_cpu   = "1"
      controller_resources_limits_mem   = "768Mi"
      controller_resources_requests_cpu = "0.2"
      controller_resources_requests_mem = "256Mi"
      server_replicas                   = "1"
      sso_issuer                        = "https://${local.argocd_fqdn}/api/dex"
      workflows_namespaces              = "monitoring"
    })
  ]

  depends_on = [
    kubernetes_namespace_v1.argo_workflows,
  ]
}

# Get the ALB hostname for the ArgoCD server ingress
data "kubernetes_ingress_v1" "argocd" {
  metadata {
    name      = "argocd-server"
    namespace = kubernetes_namespace_v1.argocd.metadata[0].name
  }
  depends_on = [helm_release.argocd]
}

# Cloudflare DNS record for ArgoCD
resource "cloudflare_record" "argocd_dev_qa_automation" {
  name    = "argocd-${var.env}-${var.application}"
  proxied = false
  ttl     = 1
  type    = "CNAME"
  value   = data.kubernetes_ingress_v1.argocd.status[0].load_balancer[0].ingress[0].hostname
  zone_id = var.dns_zone["zone_id"]
  tags    = [var.env, var.application]
}

# Get the ALB hostname for the Argo Workflows server ingress
data "kubernetes_ingress_v1" "argowfs" {
  metadata {
    name      = "argo-workflows-server"
    namespace = kubernetes_namespace_v1.argo_workflows.metadata[0].name
  }
  depends_on = [helm_release.argo_workflows]
}

# Cloudflare DNS record for Argo Workflows
resource "cloudflare_record" "argowfs_dev_qa_automation" {
  name    = "argowfs-${var.env}-${var.application}"
  proxied = false
  ttl     = 1
  type    = "CNAME"
  value   = data.kubernetes_ingress_v1.argowfs.status[0].load_balancer[0].ingress[0].hostname
  zone_id = var.dns_zone["zone_id"]
}
