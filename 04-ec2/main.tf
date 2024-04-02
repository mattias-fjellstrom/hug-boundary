data "tfe_outputs" "platform" {
  workspace = "02-platform"
}

data "tfe_outputs" "boundary" {
  workspace = "03-boundary"
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "ubuntu_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical account ID
}
