data "aws_eks_cluster_auth" "this" {
  name = aws_eks_cluster.this.name

  depends_on = [
    aws_eks_cluster.this,
    aws_eks_node_group.nodes,
  ]
}

resource "kubernetes_storage_class" "ebs_sc" {
  metadata {
    name = "ebs-sc"
  }
  storage_provisioner = "ebs.csi.aws.com"
  volume_binding_mode = "WaitForFirstConsumer"

  depends_on = [
    aws_eks_addon.csi,
  ]
}
