resource "tfe_workspace" "oncall" {
  name               = "08-on-call-demo"
  description        = "Components for the on-call demo"
  project_id         = tfe_project.hug.id
  allow_destroy_plan = true

  working_directory     = "./08-on-call-demo"
  file_triggers_enabled = true
  auto_apply            = false
  force_delete          = true

  vcs_repo {
    identifier                 = var.github_repository_identifier
    github_app_installation_id = data.tfe_github_app_installation.this.id
    branch                     = "main"
  }
}

resource "tfe_workspace_settings" "oncall" {
  workspace_id   = tfe_workspace.oncall.id
  execution_mode = "remote"
}
