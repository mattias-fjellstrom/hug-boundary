resource "aws_security_group" "node" {
  description            = "EKS node shared security group"
  name_prefix            = "eks-${var.aws_region}-node-"
  revoke_rules_on_delete = false

  tags = {
    Name = "eks-${var.aws_region}-node"
    "kubernetes.io/cluster/eks-${var.aws_region}" : "owned"
  }

  vpc_id = data.tfe_outputs.platform.values.aws_vpc.id
}

resource "aws_security_group_rule" "egress_http" {
  description       = "Allow HTTP egress"
  type              = "egress"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.node.id
}

resource "aws_security_group_rule" "egress_https" {
  description       = "Allow HTTPS egress"
  type              = "egress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.node.id
}

resource "aws_security_group_rule" "egress_boundary" {
  description = "Allow outbound Boundary worker communication in the same subnet"
  type        = "egress"
  protocol    = "tcp"
  from_port   = 9202
  to_port     = 9202
  cidr_blocks = [
    data.tfe_outputs.platform.values.private_subnets[0].cidr_block,
    data.tfe_outputs.platform.values.private_subnets[1].cidr_block,
    data.tfe_outputs.platform.values.private_subnets[2].cidr_block,
  ]
  security_group_id = aws_security_group.node.id
}

resource "aws_security_group_rule" "ingress_cluster_443" {
  description              = "Cluster API to node groups"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 443
  to_port                  = 443
  security_group_id        = aws_security_group.node.id
  source_security_group_id = aws_security_group.cluster.id
}

resource "aws_security_group_rule" "ingress_cluster_4443_webhook" {
  description              = "Cluster API to node 4443/tcp webhook"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 4443
  to_port                  = 4443
  security_group_id        = aws_security_group.node.id
  source_security_group_id = aws_security_group.cluster.id
}

resource "aws_security_group_rule" "ingress_cluster_6443_webhook" {
  description              = "Cluster API to node 6443/tcp webhook"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 6443
  to_port                  = 6443
  security_group_id        = aws_security_group.node.id
  source_security_group_id = aws_security_group.cluster.id
}

resource "aws_security_group_rule" "ingress_cluster_8443_webhook" {
  description              = "Cluster API to node 8443/tcp webhook"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 8443
  to_port                  = 8443
  security_group_id        = aws_security_group.node.id
  source_security_group_id = aws_security_group.cluster.id
}

resource "aws_security_group_rule" "ingress_cluster_9443_webhook" {
  description              = "Cluster API to node 9443/tcp webhook"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 9443
  to_port                  = 9443
  security_group_id        = aws_security_group.node.id
  source_security_group_id = aws_security_group.cluster.id
}

resource "aws_security_group_rule" "ingress_cluster_kubelet" {
  description              = "Cluster API to node kubelets"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 10250
  to_port                  = 10250
  security_group_id        = aws_security_group.node.id
  source_security_group_id = aws_security_group.cluster.id
}

resource "aws_security_group_rule" "ingress_nodes_ephemeral" {
  description              = "Node to node ingress on ephemeral ports"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 1025
  to_port                  = 65535
  security_group_id        = aws_security_group.node.id
  source_security_group_id = aws_security_group.node.id
}

resource "aws_security_group_rule" "ingress_self_coredns_tcp" {
  description              = "Node to node CoreDNS"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 53
  to_port                  = 53
  security_group_id        = aws_security_group.node.id
  source_security_group_id = aws_security_group.node.id
}

resource "aws_security_group_rule" "ingress_self_coredns_udp" {
  description              = "Node to node CoreDNS UDP"
  type                     = "ingress"
  protocol                 = "udp"
  from_port                = 53
  to_port                  = 53
  security_group_id        = aws_security_group.node.id
  source_security_group_id = aws_security_group.node.id
}

resource "aws_launch_template" "nodes" {
  description            = "Launch template for AWS EKS managed node group"
  name_prefix            = "mng-"
  update_default_version = true

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "node-group-1"
    }
  }

  tag_specifications {
    resource_type = "network-interface"
    tags = {
      Name = "node-group-1"
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name = "node-group-1"
    }
  }
}

resource "aws_eks_node_group" "nodes" {
  ami_type     = "AL2_x86_64"
  cluster_name = aws_eks_cluster.this.name
  instance_types = [
    "t3.small"
  ]
  node_group_name_prefix = "node-group-1-"
  node_role_arn          = aws_iam_role.nodes.arn

  subnet_ids = [
    data.tfe_outputs.platform.values.private_subnets[0].id,
    data.tfe_outputs.platform.values.private_subnets[1].id,
    data.tfe_outputs.platform.values.private_subnets[2].id,
  ]
  tags = {
    Name = "node-group-1"
  }
  version = "1.29"

  launch_template {
    name    = aws_launch_template.nodes.name
    version = aws_launch_template.nodes.latest_version
  }

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  update_config {
    max_unavailable_percentage = 33
  }
}
