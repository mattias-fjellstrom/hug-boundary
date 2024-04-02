output "aws_key_pair_name" {
  value = aws_key_pair.ec2.key_name
}

output "aws_s3_bucket" {
  description = "Session recording S3 bucket resource"
  value       = aws_s3_bucket.session_recording
}

output "aws_vpc" {
  description = "AWS VPC resource"
  value       = aws_vpc.this
}

output "aws_cloudwatch_security_group" {
  description = "Security group for AWS CloudWatch VPC Endpoint"
  value       = aws_security_group.logs
}

output "boundary_cluster" {
  description = "HCP Boundary cluster resource"
  value       = hcp_boundary_cluster.this
  sensitive   = true
}

output "dba_group" {
  description = "Entra ID group for DBAs"
  value = {
    id = azuread_group.dba.object_id
  }
}

output "k8s_group" {
  description = "Entra ID group for kubernetes administrators"
  value = {
    id = azuread_group.k8s.object_id
  }
}

output "oncall_group" {
  description = "Entra ID group for on-call engineers"
  value = {
    id = azuread_group.oncall.object_id
  }
}

output "oidc_configuration" {
  description = "Entra ID OIDC application configuration"
  value = {
    client_id     = azuread_application.oidc.client_id
    client_secret = azuread_application_password.oidc.value
    tenant_id     = data.azuread_client_config.current.tenant_id
  }
  sensitive = true
}

output "sre_group" {
  description = "Entra ID group for site-reliability engineers"
  value = {
    id = azuread_group.sre.object_id
  }
}

output "vault_admin_token" {
  description = "Vault admin token for authentication"
  sensitive   = true
  value       = hcp_vault_cluster_admin_token.this.token
}

output "vault_private_endpoint_url" {
  description = "Vault cluster private endpoint URL"
  value       = hcp_vault_cluster.this.vault_private_endpoint_url
}

output "vault_public_endpoint_url" {
  description = "Vault cluster public endpoint URL"
  value       = hcp_vault_cluster.this.vault_public_endpoint_url
}

output "public_subnets" {
  description = "List of public subnets"
  value = [
    aws_subnet.public01,
    aws_subnet.public02,
    aws_subnet.public03,
  ]
}

output "private_subnets" {
  description = "List of private subnets"
  value = [
    aws_subnet.private01,
    aws_subnet.private02,
    aws_subnet.private03,
  ]
}

output "isolated_subnets" {
  description = "List of isolated subnets"
  value = [
    aws_subnet.isolated01,
    aws_subnet.isolated02,
    aws_subnet.isolated03,
  ]
}

output "hcp_cidr_range" {
  description = "CIDR range for HCP HVN network"
  value       = var.hcp_virtual_network_cidr
}
