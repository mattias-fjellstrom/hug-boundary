packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "amazon_linux" {
  ami_name      = "boundary-worker"
  instance_type = "t3.micro"
  region        = "eu-west-1"

  source_ami_filter {
    filters = {
      name                = "amzn2-ami-hvm*-x86_64-gp2"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["amazon"]
  }
  ssh_username = "ec2-user"
}

build {
  hcp_packer_registry {
    bucket_name = "boundary"
    description = "Boundary worker based on Amazon Linux"

    bucket_labels = {
      "os"    = "Amazon Linux",
    }

    build_labels = {
      "build-time"   = timestamp()
      "build-source" = basename(path.cwd)
    }
  }

  name = "boundary-worker-build"

  sources = [
    "source.amazon-ebs.amazon_linux"
  ]

  provisioner "shell" {
    inline = [
      "sudo yum install -y yum-utils shadow-utils",
      "sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo",
      "sudo yum -y install boundary-enterprise amazon-cloudwatch-agent",
      "sudo mkdir /etc/boundary.d/worker"
    ]
  }
}
