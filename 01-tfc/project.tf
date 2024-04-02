resource "tfe_project" "hug" {
  name = "hashicorp-user-group"
}

resource "tfe_project_variable_set" "aws" {
  variable_set_id = tfe_variable_set.aws.id
  project_id      = tfe_project.hug.id
}

resource "tfe_project_variable_set" "azure" {
  variable_set_id = tfe_variable_set.azure.id
  project_id      = tfe_project.hug.id
}

resource "tfe_project_variable_set" "tfe" {
  variable_set_id = tfe_variable_set.tfe.id
  project_id      = tfe_project.hug.id
}

resource "tfe_project_variable_set" "hcp" {
  variable_set_id = tfe_variable_set.hcp.id
  project_id      = tfe_project.hug.id
}
