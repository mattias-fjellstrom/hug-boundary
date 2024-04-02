# COMMON ---------------------------------------------------------------------------------------------------------------
locals {
  private_target_private_ip  = "10.0.110.30"
  isolated_target_private_ip = "10.0.210.30"
}

resource "boundary_host_catalog_static" "aws" {
  name        = "AWS Static Host Catalog"
  description = "AWS EC2 static hosts"
  scope_id    = data.boundary_scope.aws.id
}

resource "time_sleep" "wait_for_vault" {
  create_duration = "2m"
  depends_on = [
    vault_mount.ssh,
    vault_ssh_secret_backend_ca.ssh_backend,
    vault_ssh_secret_backend_role.boundary_client,
  ]
}

data "http" "public_key" {
  method = "GET"
  url    = "${data.tfe_outputs.platform.values.vault_public_endpoint_url}/v1/ssh-client-signer/public_key"
  request_headers = {
    "X-Vault-Namespace" = "admin"
  }

  depends_on = [
    time_sleep.wait_for_vault,
  ]
}

data "cloudinit_config" "ec2" {
  gzip          = false
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      = <<-EOF
      #!/bin/bash
      echo "${data.http.public_key.response_body}" >> /etc/ssh/trusted-user-ca-keys.pem
      echo 'TrustedUserCAKeys /etc/ssh/trusted-user-ca-keys.pem' | sudo tee -a /etc/ssh/sshd_config
      sudo systemctl restart sshd.service
    EOF
  }
}

# PRIVATE TARGET -------------------------------------------------------------------------------------------------------
resource "boundary_host_static" "ec2_private" {
  name            = "aws-ec2-static-private"
  description     = "A sample Ubuntu EC2 running in a private subnet"
  address         = local.private_target_private_ip
  host_catalog_id = boundary_host_catalog_static.aws.id
}

resource "boundary_host_set_static" "ec2_private" {
  name            = "aws-ec2-static-private-host-set"
  description     = "Host set for static AWS EC2 running in a private subnet"
  host_catalog_id = boundary_host_catalog_static.aws.id
  host_ids = [
    boundary_host_static.ec2_private.id,
  ]
}

resource "boundary_target" "ec2_private" {
  type                     = "ssh"
  name                     = "aws-ec2-static-private"
  description              = "AWS EC2 statically created hosts in a private subnet"
  ingress_worker_filter    = "\"public\" in \"/tags/subnet\""
  egress_worker_filter     = "\"private\" in \"/tags/subnet\""
  scope_id                 = data.boundary_scope.aws.id
  session_connection_limit = -1
  default_port             = 22
  host_source_ids = [
    boundary_host_set_static.ec2_private.id,
  ]
  injected_application_credential_source_ids = [boundary_credential_library_vault_ssh_certificate.ec2.id]

  # uncomment to enable session recording
  enable_session_recording = true
  storage_bucket_id        = boundary_storage_bucket.session_recording.id
}

resource "aws_security_group" "ec2_private" {
  name        = "private-static-hosts"
  description = "Security group for static hosts in a private subnet"
  vpc_id      = data.tfe_outputs.platform.values.aws_vpc.id

  // inbound traffic from boundary worker
  ingress {
    description = "Allow traffic from same subnet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [
      data.tfe_outputs.platform.values.private_subnets[0].cidr_block,
      data.tfe_outputs.platform.values.private_subnets[1].cidr_block,
      data.tfe_outputs.platform.values.private_subnets[2].cidr_block,
    ]
  }

  // allow outbound traffic to the internet
  egress {
    description = "Allow traffic to the internet"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Static EC2 (private)"
  }
}

resource "aws_instance" "ec2_private" {
  ami                    = data.aws_ami.ubuntu_ami.id
  instance_type          = var.aws_instance_type
  vpc_security_group_ids = [aws_security_group.ec2_private.id]
  subnet_id              = data.tfe_outputs.platform.values.private_subnets[0].id
  availability_zone      = data.aws_availability_zones.available.names[0]

  user_data_base64            = data.cloudinit_config.ec2.rendered
  private_ip                  = local.private_target_private_ip
  associate_public_ip_address = false

  tags = {
    Name = "Boundary Target (static, private)"
  }

  lifecycle {
    ignore_changes = [user_data_base64]
  }
}

# ISOLATED TARGET ------------------------------------------------------------------------------------------------------
resource "boundary_host_static" "ec2_isolated" {
  name            = "aws-ec2-static-isolated"
  description     = "A sample Ubuntu EC2 running in an isolated subnet"
  address         = local.isolated_target_private_ip
  host_catalog_id = boundary_host_catalog_static.aws.id
}

resource "boundary_host_set_static" "ec2_isolated" {
  name            = "aws-ec2-static-isolated-host-set"
  description     = "Host set for static AWS EC2 running in an isolated subnet"
  host_catalog_id = boundary_host_catalog_static.aws.id
  host_ids = [
    boundary_host_static.ec2_isolated.id,
  ]
}

resource "boundary_target" "ec2_isolated" {
  type                     = "ssh"
  name                     = "aws-ec2-static-isolated"
  description              = "AWS EC2 statically created hosts in an isolated subnet"
  ingress_worker_filter    = "\"public\" in \"/tags/subnet\""
  egress_worker_filter     = "\"isolated\" in \"/tags/subnet\""
  scope_id                 = data.boundary_scope.aws.id
  session_connection_limit = -1
  default_port             = 22
  host_source_ids = [
    boundary_host_set_static.ec2_isolated.id,
  ]
  injected_application_credential_source_ids = [boundary_credential_library_vault_ssh_certificate.ec2.id]

  # uncomment to enable session recording
  enable_session_recording = true
  storage_bucket_id        = boundary_storage_bucket.session_recording.id
}

resource "aws_security_group" "ec2_isolated" {
  name        = "isolated-static-hosts"
  description = "Security group for static hosts in an isolated subnet"
  vpc_id      = data.tfe_outputs.platform.values.aws_vpc.id

  // inbound traffic from boundary worker
  ingress {
    description = "Allow traffic from same subnet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [
      data.tfe_outputs.platform.values.isolated_subnets[0].cidr_block,
      data.tfe_outputs.platform.values.isolated_subnets[1].cidr_block,
      data.tfe_outputs.platform.values.isolated_subnets[2].cidr_block,
    ]
  }

  tags = {
    Name = "Static EC2 (isolated)"
  }
}

resource "aws_instance" "ec2_isolated" {
  ami                    = data.aws_ami.ubuntu_ami.id
  instance_type          = var.aws_instance_type
  vpc_security_group_ids = [aws_security_group.ec2_isolated.id]
  subnet_id              = data.tfe_outputs.platform.values.isolated_subnets[0].id
  availability_zone      = data.aws_availability_zones.available.names[0]

  user_data_base64            = data.cloudinit_config.ec2.rendered
  private_ip                  = local.isolated_target_private_ip
  associate_public_ip_address = false

  tags = {
    Name = "Boundary Target (static, isolated)"
  }

  lifecycle {
    ignore_changes = [user_data_base64]
  }
}
