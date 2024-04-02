resource "tfe_workspace" "lambda" {
  name               = "07-lambda"
  description        = "Lambda components for HUG demo"
  project_id         = tfe_project.hug.id
  allow_destroy_plan = true

  working_directory     = "./07-lambda"
  file_triggers_enabled = true
  auto_apply            = false
  force_delete          = true

  vcs_repo {
    identifier                 = var.github_repository_identifier
    github_app_installation_id = data.tfe_github_app_installation.this.id
    branch                     = "main"
  }
}

resource "tfe_workspace_settings" "lambda" {
  workspace_id   = tfe_workspace.lambda.id
  execution_mode = "remote"
}
