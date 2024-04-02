# NETWORKING -----------------------------------------------------------------------------------------------------------
resource "aws_security_group" "cluster" {
  description            = "EKS cluster security group"
  name_prefix            = "eks-${var.aws_region}-cluster-"
  revoke_rules_on_delete = false
  vpc_id                 = data.tfe_outputs.platform.values.aws_vpc.id
  tags = {
    Name = "eks-${var.aws_region}-cluster"
  }
}

resource "aws_security_group_rule" "ingress_nodes_443" {
  description              = "Node groups to cluster API"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 443
  to_port                  = 443
  security_group_id        = aws_security_group.cluster.id
  source_security_group_id = aws_security_group.node.id
}

resource "aws_security_group_rule" "ingress_private_subnet" {
  description       = "Private subnet to cluster API"
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  security_group_id = aws_security_group.cluster.id
  cidr_blocks = [
    data.tfe_outputs.platform.values.private_subnets[0].cidr_block,
    data.tfe_outputs.platform.values.private_subnets[1].cidr_block,
    data.tfe_outputs.platform.values.private_subnets[2].cidr_block,
  ]
}

# CLUSTER --------------------------------------------------------------------------------------------------------------
resource "aws_eks_cluster" "this" {
  name     = "eks-${var.aws_region}"
  version  = "1.29"
  role_arn = aws_iam_role.cluster.arn

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  kubernetes_network_config {
    ip_family         = "ipv4"
    service_ipv4_cidr = "172.16.0.0/12"
  }

  vpc_config {
    security_group_ids = [
      aws_security_group.cluster.id,
    ]

    endpoint_private_access = true
    endpoint_public_access  = false

    subnet_ids = [
      data.tfe_outputs.platform.values.private_subnets[0].id,
      data.tfe_outputs.platform.values.private_subnets[1].id,
      data.tfe_outputs.platform.values.private_subnets[2].id,
    ]
  }
}

# ADDONS ---------------------------------------------------------------------------------------------------------------
resource "aws_eks_addon" "csi" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "aws-ebs-csi-driver"
  addon_version               = "v1.29.1-eksbuild.1"
  resolve_conflicts_on_update = "PRESERVE"
  service_account_role_arn    = aws_iam_role.csi.arn
}
