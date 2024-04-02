# BOUNDARY WORKER ------------------------------------------------------------------------------------------------------
resource "kubernetes_service" "boundary" {
  metadata {
    name = "boundary-worker"
    labels = {
      app = "boundary-worker"
    }
  }
  spec {
    selector = {
      app = "boundary-worker"
    }

    port {
      name = "proxy"
      port = 9202
    }

    port {
      name = "ops"
      port = 9203
    }

    cluster_ip = "None"
  }

  depends_on = [
    aws_eks_addon.csi,
  ]
}

resource "kubernetes_config_map" "boundary" {
  metadata {
    name = "boundary-worker-configuration"
  }
  immutable = false
  data = {
    "worker.hcl" = <<-EOF
        disable_mlock = true

        listener "tcp" {
            address = "0.0.0.0:9202"
            purpose = "proxy"
        }

        listener "tcp" {
            address     = "0.0.0.0:9203"
            purpose     = "ops"
            tls_disable = true
        }

        worker {
            controller_generated_activation_token = "env://CONTROLLER_GENERATED_ACTIVATION_TOKEN"
            initial_upstreams                     = ["${data.tfe_outputs.boundary.values.private_worker_ip}:9202"]
            auth_storage_path                     = "/opt/boundary/data"
            tags {
                type      = ["pki", "kubernetes"]
                namespace = "default"
            }
        }
    EOF
  }

  depends_on = [
    aws_eks_addon.csi,
  ]
}

resource "kubernetes_persistent_volume_claim" "boundary" {
  metadata {
    name = "boundary-worker-storage-volume"
  }
  spec {
    access_modes = [
      "ReadWriteOnce"
    ]
    storage_class_name = kubernetes_storage_class.ebs_sc.metadata[0].name
    resources {
      requests = {
        storage = "1Gi"
      }
    }
  }

  depends_on = [
    aws_eks_addon.csi,
  ]
}

resource "kubernetes_deployment" "boundary" {
  metadata {
    name = "boundary-worker"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "boundary-worker"
      }
    }

    template {
      metadata {
        labels = {
          app = "boundary-worker"
        }
      }

      spec {
        security_context {
          run_as_user  = 998
          run_as_group = 996
          fs_group     = 996
        }

        volume {
          name = "boundary-worker-configuration-volume"
          config_map {
            name         = "boundary-worker-configuration"
            default_mode = "0420"
          }
        }

        volume {
          name = "boundary-worker-storage-volume"
          persistent_volume_claim {
            claim_name = "boundary-worker-storage-volume"
          }
        }

        container {
          image = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/boundary-worker:latest"

          resources {}

          liveness_probe {
            http_get {
              path   = "/health"
              port   = 9203
              scheme = "HTTP"
            }
            initial_delay_seconds = 5
            timeout_seconds       = 1
            period_seconds        = 15
            success_threshold     = 1
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path   = "/health"
              port   = 9203
              scheme = "HTTP"
            }
            initial_delay_seconds = 5
            timeout_seconds       = 1
            period_seconds        = 15
            success_threshold     = 1
            failure_threshold     = 3
          }

          name = "boundary-worker"

          env {
            name  = "CONTROLLER_GENERATED_ACTIVATION_TOKEN"
            value = boundary_worker.kubernetes.controller_generated_activation_token
          }

          port {
            name           = "proxy"
            container_port = 9202
            protocol       = "TCP"
          }

          port {
            name           = "metrics"
            container_port = 9203
            protocol       = "TCP"
          }

          image_pull_policy = "Always"

          volume_mount {
            name       = "boundary-worker-configuration-volume"
            mount_path = "/opt/boundary/config/"
          }

          volume_mount {
            name       = "boundary-worker-storage-volume"
            mount_path = "/opt/boundary/data/"
          }
        }
      }
    }
  }

  depends_on = [
    aws_eks_addon.csi,
  ]
}
