resource "vault_policy" "boundary_controller" {
  name   = "boundary-controller"
  policy = file("boundary-controller-policy.hcl")
}
