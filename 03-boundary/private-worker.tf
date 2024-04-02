# NETWORKING -----------------------------------------------------------------------------------------------------------
resource "aws_security_group" "private_worker" {
  name        = "boundary_private_workers"
  description = "Security group for private workers"
  vpc_id      = data.tfe_outputs.platform.values.aws_vpc.id

  tags = {
    Name = "Private Workers"
  }
}

resource "aws_security_group_rule" "ingress_isolated_to_private" {
  description              = "Allow isolated workers to talk to private workers"
  security_group_id        = aws_security_group.private_worker.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 9202
  to_port                  = 9202
  source_security_group_id = aws_security_group.isolated_worker.id
}

resource "aws_security_group_rule" "ingress_eks_to_private" {
  description       = "Allow inbound from workers in the same subnet (i.e. for EKS)"
  security_group_id = aws_security_group.private_worker.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 9202
  to_port           = 9202
  cidr_blocks = [
    data.tfe_outputs.platform.values.private_subnets[0].cidr_block,
    data.tfe_outputs.platform.values.private_subnets[1].cidr_block,
    data.tfe_outputs.platform.values.private_subnets[2].cidr_block,
  ]
}

resource "aws_security_group_rule" "egress_private_to_hcp_vault" {
  description       = "Allow outbound to HCP Vault peered VPC"
  security_group_id = aws_security_group.private_worker.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 8200
  to_port           = 8200
  cidr_blocks = [
    data.tfe_outputs.platform.values.hcp_cidr_range
  ]
}

resource "aws_security_group_rule" "egress_private_to_public" {
  description              = "Allow private workers to talk to public workers"
  security_group_id        = aws_security_group.private_worker.id
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 9202
  to_port                  = 9202
  source_security_group_id = aws_security_group.public_worker.id
}

resource "aws_security_group_rule" "egress_private_to_targets" {
  description       = "Allow private workers to talk SSH to targets in the same subnet"
  security_group_id = aws_security_group.private_worker.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_blocks = [
    data.tfe_outputs.platform.values.private_subnets[0].cidr_block,
    data.tfe_outputs.platform.values.private_subnets[1].cidr_block,
    data.tfe_outputs.platform.values.private_subnets[2].cidr_block,
  ]
}

resource "aws_security_group_rule" "egress_private_to_postgres" {
  description       = "Allow private workers to talk to postgres in the same subnet"
  security_group_id = aws_security_group.private_worker.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 5432
  to_port           = 5432
  cidr_blocks = [
    data.tfe_outputs.platform.values.private_subnets[0].cidr_block,
    data.tfe_outputs.platform.values.private_subnets[1].cidr_block,
    data.tfe_outputs.platform.values.private_subnets[2].cidr_block,
  ]
}

resource "aws_security_group_rule" "egress_private_to_cloudwatch" {
  description              = "Allow outbound 443 to CloudWatch service endpoint"
  security_group_id        = aws_security_group.private_worker.id
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 443
  to_port                  = 443
  source_security_group_id = data.tfe_outputs.platform.values.aws_cloudwatch_security_group.id
}

resource "aws_security_group_rule" "egress_private_to_internet_80" {
  description       = "Allow outbound port 80 to the internet"
  security_group_id = aws_security_group.private_worker.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "egress_private_to_internet_443" {
  description       = "Allow outbound port 80 to the internet"
  security_group_id = aws_security_group.private_worker.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["0.0.0.0/0"]
}

# WORKER ---------------------------------------------------------------------------------------------------------------
resource "boundary_worker" "private" {
  scope_id = boundary_scope.global.id
  name     = "private-worker"

  // leave empty for controller led worker registration
  worker_generated_auth_token = ""
}

locals {
  private_worker_config = templatefile("./templates/worker.hcl.tftpl", {
    is_ingress                            = false
    hcp_boundary_cluster_id               = ""
    audit_enabled                         = true
    observations_enabled                  = true
    sysevents_enabled                     = true
    initial_upstreams                     = ["${module.public_worker.private_ip}:9202"]
    controller_generated_activation_token = boundary_worker.private.controller_generated_activation_token
    tags = {
      type   = "pki"
      vault  = "true"
      subnet = "private"
      region = var.aws_region
      az     = data.tfe_outputs.platform.values.private_subnets[0].availability_zone
    }
  })
}

module "private_worker" {
  providers = {
    aws = aws
  }
  source = "./modules/worker"

  aws_ec2_key_name                         = data.tfe_outputs.platform.values.aws_key_pair_name
  aws_instance_associate_public_ip_address = false
  aws_instance_ami_id                      = data.hcp_packer_artifact.boundary.external_identifier
  aws_instance_profile_name                = aws_iam_instance_profile.workers.name
  aws_instance_tags = {
    Name = "Boundary Worker (private)"
  }
  aws_instance_type      = var.aws_worker_instance_type
  aws_region             = var.aws_region
  aws_security_group_id  = aws_security_group.private_worker.id
  aws_subnet             = data.tfe_outputs.platform.values.private_subnets[0]
  boundary_worker_config = local.private_worker_config
}
