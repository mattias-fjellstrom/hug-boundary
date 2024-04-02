resource "tfe_workspace" "eks" {
  name               = "05-eks"
  description        = "EKS components for HUG demo"
  project_id         = tfe_project.hug.id
  allow_destroy_plan = true

  working_directory     = "./05-eks"
  file_triggers_enabled = true
  auto_apply            = false
  force_delete          = true

  vcs_repo {
    identifier                 = var.github_repository_identifier
    github_app_installation_id = data.tfe_github_app_installation.this.id
    branch                     = "main"
  }
}

resource "tfe_workspace_settings" "eks" {
  workspace_id   = tfe_workspace.eks.id
  execution_mode = "agent"
  agent_pool_id  = tfe_agent_pool.aws.id
}
