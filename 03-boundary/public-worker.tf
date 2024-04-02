# NETWORKING -----------------------------------------------------------------------------------------------------------
resource "aws_security_group" "public_worker" {
  name        = "boundary_public_workers"
  description = "Security group for public workers"
  vpc_id      = data.tfe_outputs.platform.values.aws_vpc.id

  tags = {
    Name = "Public Workers"
  }
}

resource "aws_security_group_rule" "ingress_boundary_clients" {
  description       = "Inbound access from Boundary clients"
  security_group_id = aws_security_group.public_worker.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 9202
  to_port           = 9202
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "egress_public_to_hcp" {
  description       = "Allow outbound port 9202 to the internet (for Boundary)"
  security_group_id = aws_security_group.public_worker.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 9202
  to_port           = 9202
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "egress_public_to_cloudwatch" {
  description              = "Allow outbound 443 to CloudWatch service endpoint"
  security_group_id        = aws_security_group.public_worker.id
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 443
  to_port                  = 443
  source_security_group_id = data.tfe_outputs.platform.values.aws_cloudwatch_security_group.id
}

resource "aws_security_group_rule" "egress_public_to_internet_80" {
  description       = "Allow outbound port 80 to the internet"
  security_group_id = aws_security_group.public_worker.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "egress_public_to_internet_443" {
  description       = "Allow outbound port 80 to the internet"
  security_group_id = aws_security_group.public_worker.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["0.0.0.0/0"]
}

# WORKER ---------------------------------------------------------------------------------------------------------------
resource "boundary_worker" "public" {
  scope_id = boundary_scope.global.id
  name     = "public-worker"

  // leave empty for controller led worker registration
  worker_generated_auth_token = ""
}

locals {
  public_worker_config = templatefile("./templates/worker.hcl.tftpl", {
    is_ingress                            = true
    hcp_boundary_cluster_id               = split(".", split("//", data.tfe_outputs.platform.values.boundary_cluster.cluster_url)[1])[0]
    audit_enabled                         = true
    observations_enabled                  = true
    sysevents_enabled                     = true
    initial_upstreams                     = []
    controller_generated_activation_token = boundary_worker.public.controller_generated_activation_token
    tags = {
      type   = "pki"
      subnet = "public"
      vault  = "false"
      region = var.aws_region
      az     = data.tfe_outputs.platform.values.isolated_subnets[0].availability_zone
    }
  })
}

module "public_worker" {
  providers = {
    aws = aws
  }
  source = "./modules/worker"

  aws_ec2_key_name                         = data.tfe_outputs.platform.values.aws_key_pair_name
  aws_instance_associate_public_ip_address = true
  aws_instance_ami_id                      = data.hcp_packer_artifact.boundary.external_identifier
  aws_instance_profile_name                = aws_iam_instance_profile.workers.name
  aws_instance_tags = {
    Name = "Boundary Worker (public)"
  }
  aws_instance_type      = var.aws_worker_instance_type
  aws_region             = var.aws_region
  aws_security_group_id  = aws_security_group.public_worker.id
  aws_subnet             = data.tfe_outputs.platform.values.public_subnets[0]
  boundary_worker_config = local.public_worker_config
}
