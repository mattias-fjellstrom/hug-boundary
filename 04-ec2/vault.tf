resource "vault_policy" "ssh" {
  name   = "ssh"
  policy = file("ssh-policy.hcl")
}

resource "vault_mount" "ssh" {
  path        = "ssh-client-signer"
  type        = "ssh"
  description = "SSH Mount"
}

resource "vault_ssh_secret_backend_role" "boundary_client" {
  name                    = "boundary-client"
  backend                 = vault_mount.ssh.path
  key_type                = "ca"
  allow_host_certificates = true
  allow_user_certificates = true
  default_user            = "ubuntu"

  default_extensions = {
    permit-pty = ""
  }

  allowed_users      = "*"
  allowed_extensions = "*"
}

resource "vault_ssh_secret_backend_ca" "ssh_backend" {
  backend              = vault_mount.ssh.path
  generate_signing_key = true
}

resource "vault_token" "boundary" {
  display_name = "boundary-token"
  policies = [
    "boundary-controller", # allow self-administration of the token
    "ssh",                 # allow working with the SSH secrets engine
  ]
  no_default_policy = true
  no_parent         = true
  renewable         = true
  ttl               = "24h"
  period            = "1h"
}
