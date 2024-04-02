resource "tfe_workspace" "boundary" {
  name               = "03-boundary"
  description        = "Boundary components for HUG demo"
  project_id         = tfe_project.hug.id
  allow_destroy_plan = true

  working_directory      = "./03-boundary"
  file_triggers_enabled  = true
  auto_apply             = true
  force_delete           = true
  auto_apply_run_trigger = true

  vcs_repo {
    identifier                 = var.github_repository_identifier
    github_app_installation_id = data.tfe_github_app_installation.this.id
    branch                     = "main"
  }
}

resource "tfe_run_trigger" "boundary" {
  workspace_id  = tfe_workspace.boundary.id
  sourceable_id = tfe_workspace.platform.id
}

resource "tfe_workspace_settings" "boundary" {
  workspace_id   = tfe_workspace.boundary.id
  execution_mode = "remote"
}
