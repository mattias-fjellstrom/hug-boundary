output "iam_user_boundary" {
  value = {
    name                  = aws_iam_user.boundary.name
    arn                   = aws_iam_user.boundary.arn
    aws_access_key_id     = aws_iam_access_key.boundary.id
    aws_secret_access_key = aws_iam_access_key.boundary.secret
  }
  sensitive = true
}

output "iam_user_vault" {
  value = {
    name                  = aws_iam_user.vault.name
    arn                   = aws_iam_user.vault.arn
    aws_access_key_id     = aws_iam_access_key.vault.id
    aws_secret_access_key = aws_iam_access_key.vault.secret
  }
  sensitive = true
}

output "boundary_managed_groups" {
  value = {
    sre    = boundary_managed_group.sre.id,
    dba    = boundary_managed_group.dba.id,
    k8s    = boundary_managed_group.k8s.id,
    oncall = boundary_managed_group.oncall.id,
  }
}

output "boundary_project_scope_id" {
  value = boundary_scope.aws.id
}

output "public_worker_ip" {
  value = module.public_worker.public_ip
}

output "private_worker_ip" {
  value = module.private_worker.private_ip
}

output "isolated_worker_ip" {
  value = module.isolated_worker.private_ip
}
