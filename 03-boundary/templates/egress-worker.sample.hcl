disable_mlock = true

listener "tcp" {
  address = "0.0.0.0:9202"
  purpose = "proxy"
}

worker {
  public_addr                           = "10.10.10.4:9202"
  initial_upstreams                     = ["10.0.10.12:9202"]
  auth_storage_path                     = "/etc/boundary.d/worker"
  recording_storage_path                = "/tmp/session-recordings"
  controller_generated_activation_token = "<TOKEN>"
  
  tags {
    type   = ["egress", "public", "pki"]
    cloud  = "aws"
    region = "eu-west-1"
    az     = "eu-west-1c"
  }
}