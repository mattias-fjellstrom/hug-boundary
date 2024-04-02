# NETWORKING -----------------------------------------------------------------------------------------------------------
resource "aws_security_group" "isolated_worker" {
  name        = "boundary_isolated_worker"
  description = "Security group for isolated workers"
  vpc_id      = data.tfe_outputs.platform.values.aws_vpc.id

  tags = {
    Name = "Isolated Workers"
  }
}

resource "aws_security_group_rule" "egress_isolated_to_private" {
  description              = "Allow isolated workers to talk to private workers"
  security_group_id        = aws_security_group.isolated_worker.id
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 9202
  to_port                  = 9202
  source_security_group_id = aws_security_group.private_worker.id
}

resource "aws_security_group_rule" "egress_isolated_to_targets" {
  description       = "Allow isolated workers to talk SSH to targets in the same subnet"
  security_group_id = aws_security_group.isolated_worker.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_blocks = [
    data.tfe_outputs.platform.values.isolated_subnets[0].cidr_block,
    data.tfe_outputs.platform.values.isolated_subnets[1].cidr_block,
    data.tfe_outputs.platform.values.isolated_subnets[2].cidr_block,
  ]
}

resource "aws_security_group_rule" "egress_isolated_to_cloudwatch" {
  description              = "Allow outbound 443 to CloudWatch service endpoint"
  security_group_id        = aws_security_group.isolated_worker.id
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 443
  to_port                  = 443
  source_security_group_id = data.tfe_outputs.platform.values.aws_cloudwatch_security_group.id
}

# WORKER ---------------------------------------------------------------------------------------------------------------
resource "boundary_worker" "isolated" {
  scope_id = boundary_scope.global.id
  name     = "isolated-worker"

  // leave empty for controller led worker registration
  worker_generated_auth_token = ""
}

locals {
  isolated_worker_config = templatefile("./templates/worker.hcl.tftpl", {
    is_ingress                            = false
    hcp_boundary_cluster_id               = ""
    audit_enabled                         = true
    observations_enabled                  = true
    sysevents_enabled                     = true
    initial_upstreams                     = ["${module.private_worker.private_ip}:9202"]
    controller_generated_activation_token = boundary_worker.isolated.controller_generated_activation_token
    tags = {
      type   = "pki"
      vault  = "false"
      subnet = "isolated"
      region = var.aws_region
      az     = data.tfe_outputs.platform.values.isolated_subnets[0].availability_zone
    }
  })
}

module "isolated_worker" {
  providers = {
    aws = aws
  }
  source = "./modules/worker"

  aws_ec2_key_name                         = data.tfe_outputs.platform.values.aws_key_pair_name
  aws_instance_associate_public_ip_address = false
  aws_instance_ami_id                      = data.hcp_packer_artifact.boundary.external_identifier
  aws_instance_profile_name                = aws_iam_instance_profile.workers.name
  aws_instance_tags = {
    Name = "Boundary Worker (isolated)"
  }
  aws_instance_type      = var.aws_worker_instance_type
  aws_region             = var.aws_region
  aws_security_group_id  = aws_security_group.isolated_worker.id
  aws_subnet             = data.tfe_outputs.platform.values.isolated_subnets[0]
  boundary_worker_config = local.isolated_worker_config
}
