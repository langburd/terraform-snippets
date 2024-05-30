output "eks_kubectl_auth" {
  value       = "aws eks update-kubeconfig --name ${aws_eks_cluster.eks.name} --region ${var.aws_region}"
  description = "Run the following command to connect to the EKS cluster"
}

output "private_subnet1" {
  value       = aws_subnet.private_subnet1.cidr_block
  description = "Private subnet CIDR block"
}

output "private_subnet2" {
  value       = aws_subnet.private_subnet2.cidr_block
  description = "Private subnet CIDR block"
}

output "eks_cluster_arn" {
  value       = aws_eks_cluster.eks.arn
  description = "EKS cluster ARN"
}

output "eks_cluster_endpoint" {
  value       = aws_eks_cluster.eks.endpoint
  description = "EKS cluster endpoint"
}

output "eks_cluster_security_group_id" {
  value       = aws_eks_cluster.eks.vpc_config[0].cluster_security_group_id
  description = "EKS cluster security group ID"
}

output "argocd_url" {
  description = "ArgoCD URL"
  value       = "https://${local.argocd_fqdn}"
}

output "argo_workflows_url" {
  description = "Argo Workflows URL"
  value       = "https://${local.argowfs_fqdn}"
}
