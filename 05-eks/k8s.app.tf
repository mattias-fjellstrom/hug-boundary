# APPLICATION ----------------------------------------------------------------------------------------------------------
resource "kubernetes_config_map" "app" {
  metadata {
    name = "nginx-config"
  }
  data = {
    "index.html" = <<-EOF
        <html>
          <style>
            @import "https://www.nerdfonts.com/assets/css/webfont.css";

            body {
              display: flex;
              background-color: #EC585D;
              color: #fff;
              margin: auto auto;
              font-family: "Gill Sans", sans-serif;
              font-size: 2em;
              align-items: center;
              justify-content: center;
            }

            h1 {
              padding: 0;
              margin-bottom: 20px;
            }

            h2 {
              padding: 0;
              margin-bottom: 10px;
            }

            p {
              padding: 0;
              margin-bottom: 10px;
            }

            .container {
              display: flex;
              flex-direction: column;
              width: 1000px;
            }
          </style>
          <body>
            <div class="container">
              <h1>HashiCorp + <i class="nf nf-fa-aws"></i></h1>
              <h2>User Group <i class="nf nf-fa-meetup"></i> Gothenburg!</h2>
              <p>This site is running on a private <strong>AWS EKS cluster</strong> <i class="nf nf-md-kubernetes"></i>.</p>
              <p>Private access is powered by <strong>HashiCorp Boundary</strong>.</p>
            </div>
          </body>
        </html>
    EOF
  }
}

resource "kubernetes_service" "app" {
  metadata {
    name = "nginx"
    labels = {
      app = "nginx"
    }
  }
  spec {
    selector = {
      app = "nginx"
    }

    port {
      name = "http"
      port = 80
    }

    cluster_ip = "None"
  }
}

resource "kubernetes_deployment" "app" {
  metadata {
    name = "nginx"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "nginx"
      }
    }

    template {
      metadata {
        labels = {
          app = "nginx"
        }
      }

      spec {
        volume {
          name = "nginx-config-volume"
          config_map {
            name         = "nginx-config"
            default_mode = "0644"
          }
        }

        container {
          name  = "boundary-worker"
          image = "nginx:latest"

          resources {}

          port {
            name           = "http"
            container_port = 80
            protocol       = "TCP"
          }

          image_pull_policy = "Always"

          volume_mount {
            name       = "nginx-config-volume"
            mount_path = "/usr/share/nginx/html"
          }
        }
      }
    }
  }
}
