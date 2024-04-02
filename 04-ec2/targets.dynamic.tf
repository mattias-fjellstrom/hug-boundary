resource "boundary_host_catalog_plugin" "aws" {
  name        = "AWS Dynamic Host Catalog"
  description = "AWS EC2 dynamic host discovery"
  scope_id    = data.boundary_scope.aws.id

  plugin_name = "aws"

  attributes_json = jsonencode({
    "region"                      = "${var.aws_region}",
    "disable_credential_rotation" = true
  })

  secrets_json = jsonencode({
    "access_key_id"     = "${data.tfe_outputs.boundary.values.iam_user_boundary.aws_access_key_id}",
    "secret_access_key" = "${data.tfe_outputs.boundary.values.iam_user_boundary.aws_secret_access_key}"
  })
}

resource "boundary_host_set_plugin" "dev" {
  name            = "aws-ubuntu-dynamic-host-set (dev)"
  description     = "Host set for dynamic AWS linux machines"
  host_catalog_id = boundary_host_catalog_plugin.aws.id

  attributes_json = jsonencode({
    "filters" = ["tag:hug=true", "tag:environment=dev"]
  })
}

resource "boundary_host_set_plugin" "prod" {
  name            = "aws-ubuntu-dynamic-host-set (prod)"
  description     = "Host set for dynamic AWS linux machines"
  host_catalog_id = boundary_host_catalog_plugin.aws.id

  attributes_json = jsonencode({
    "filters" = ["tag:hug=true", "tag:environment=prod"]
  })
}

resource "boundary_target" "dynamic_dev" {
  type                     = "ssh"
  name                     = "aws-ec2-dynamic-dev"
  description              = "AWS EC2 dynamically discovered hosts"
  ingress_worker_filter    = "\"public\" in \"/tags/subnet\""
  egress_worker_filter     = "\"private\" in \"/tags/subnet\""
  scope_id                 = data.boundary_scope.aws.id
  session_connection_limit = -1
  default_port             = 22
  host_source_ids = [
    boundary_host_set_plugin.dev.id,
  ]
  injected_application_credential_source_ids = [boundary_credential_library_vault_ssh_certificate.ec2.id]

  # uncomment to enable session recording
  enable_session_recording = true
  storage_bucket_id        = boundary_storage_bucket.session_recording.id
}

resource "boundary_target" "dynamic_prod" {
  type                     = "ssh"
  name                     = "aws-ec2-dynamic-prod"
  description              = "AWS EC2 dynamically discovered hosts"
  ingress_worker_filter    = "\"public\" in \"/tags/subnet\""
  egress_worker_filter     = "\"private\" in \"/tags/subnet\""
  scope_id                 = data.boundary_scope.aws.id
  session_connection_limit = -1
  default_port             = 22
  host_source_ids = [
    boundary_host_set_plugin.prod.id,
  ]
  injected_application_credential_source_ids = [boundary_credential_library_vault_ssh_certificate.ec2.id]

  # uncomment to enable session recording
  enable_session_recording = true
  storage_bucket_id        = boundary_storage_bucket.session_recording.id
}

resource "aws_security_group" "dynamic_hosts" {
  name        = "dynamic-hosts"
  description = "Security group for dynamic hosts"
  vpc_id      = data.tfe_outputs.platform.values.aws_vpc.id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = [
      data.tfe_outputs.platform.values.private_subnets[0].cidr_block,
      data.tfe_outputs.platform.values.private_subnets[1].cidr_block,
      data.tfe_outputs.platform.values.private_subnets[2].cidr_block,
    ]
  }

  egress {
    description = "Allow traffic to the internet"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Dynamic EC2"
  }
}

locals {
  instances = [
    {
      "Name" : "Boundary Target (dynamic, private, dev)",
      "hug" : "true",
      "environment" : "dev"
    },
    {
      "Name" : "Boundary Target (dynamic, private, dev)",
      "hug" : "true",
      "environment" : "dev"
    },
    {
      "Name" : "Boundary Target (dynamic, private, prod)",
      "hug" : "true",
      "environment" : "prod"
    },
    {
      "Name" : "Boundary Target (dynamic, private, prod)",
      "hug" : "true",
      "environment" : "prod"
    }
  ]
}

resource "aws_instance" "dynamic" {
  count                  = length(local.instances)
  ami                    = data.aws_ami.ubuntu_ami.id
  instance_type          = var.aws_instance_type
  subnet_id              = data.tfe_outputs.platform.values.private_subnets[1].id
  vpc_security_group_ids = [aws_security_group.dynamic_hosts.id]
  tags                   = local.instances[count.index]
  user_data_base64       = data.cloudinit_config.ec2.rendered
}
