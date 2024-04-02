data "hcp_organization" "current" {}

resource "hcp_service_principal" "hug" {
  name   = "hug-contributor"
  parent = data.hcp_organization.current.resource_name
}

resource "hcp_service_principal_key" "hug" {
  service_principal = hcp_service_principal.hug.resource_name
}

resource "hcp_organization_iam_binding" "hug" {
  principal_id = hcp_service_principal.hug.resource_id
  role         = "roles/contributor"
}
