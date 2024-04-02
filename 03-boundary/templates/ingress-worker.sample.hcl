disable_mlock = true

hcp_boundary_cluster_id = "7f2c0dee-8b2d-4186-a134-80330960078b"

listener "tcp" {
  address = "0.0.0.0:9202"
  purpose = "proxy"
}

worker {
  public_addr                           = "12.34.56.78:9202"
  auth_storage_path                     = "/etc/boundary.d/worker"
  recording_storage_path                = "/tmp/session-recordings"
  controller_generated_activation_token = "<TOKEN>"
  
  tags {
    type   = ["ingress", "public", "pki"]
    cloud  = "aws"
    region = "eu-west-1"
    az     = "eu-west-1a"
  }
}