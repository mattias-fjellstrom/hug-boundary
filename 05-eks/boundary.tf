data "boundary_scope" "organization" {
  scope_id = "global"
  name     = "HashiCorp User Group"
}

data "boundary_scope" "aws" {
  scope_id = data.boundary_scope.organization.id
  name     = "AWS Resources"
}

resource "boundary_worker" "kubernetes" {
  scope_id                    = data.boundary_scope.organization.id
  name                        = "kubernetes-worker-1"
  worker_generated_auth_token = ""
}

resource "boundary_target" "kubernetes_nginx" {
  name        = "aws-eks-nginx-app"
  description = "Nginx pod running on an AWS EKS cluster"
  scope_id    = data.boundary_scope.aws.id

  type         = "tcp"
  address      = "nginx.default.svc.cluster.local"
  default_port = 80

  ingress_worker_filter = "\"public\" in \"/tags/subnet\""
  egress_worker_filter  = "\"kubernetes\" in \"/tags/type\""
  # egress_worker_filter  = "\"private\" in \"/tags/subnet\""
}

resource "boundary_role" "k8s_app_access" {
  name        = "k8s-app-access"
  description = "Access to Kubernetes applications"
  scope_id    = data.boundary_scope.aws.id
  grant_strings = [
    "ids=*;type=*;actions=list,no-op",
    "ids=${boundary_target.kubernetes_nginx.id};actions=read,authorize-session",
  ]
  principal_ids = [
    data.tfe_outputs.boundary.values.boundary_managed_groups.k8s,
  ]
}
