resource "tfe_workspace" "platform" {
  name               = "02-platform"
  description        = "Platform components for HUG demo"
  project_id         = tfe_project.hug.id
  allow_destroy_plan = true

  working_directory     = "./02-platform"
  file_triggers_enabled = true
  auto_apply            = true

  vcs_repo {
    identifier                 = var.github_repository_identifier
    github_app_installation_id = data.tfe_github_app_installation.this.id
    branch                     = "main"
  }

  depends_on = [
    tfe_project_variable_set.azure,
    tfe_variable_set.azure,
    tfe_variable.arm_client_id,
    tfe_variable.arm_client_secret,
    tfe_variable.arm_subscription_id,
    tfe_variable.arm_tenant_id,
  ]
}

resource "tfe_workspace_settings" "platform" {
  workspace_id   = tfe_workspace.platform.id
  execution_mode = "remote"
}

resource "tfe_variable" "hcp_boundary_admin_password" {
  key          = "hcp_boundary_admin_password"
  value        = var.hcp_boundary_admin_password
  workspace_id = tfe_workspace.platform.id
  category     = "terraform"
  description  = "HCP Boundary admin password"
  sensitive    = true
}
