data "tfe_agent_pool" "aws" {
  name = "aws-agent-pool"
}

data "tfe_workspace" "eks" {
  name = "05-eks"
}

resource "tfe_agent_pool_allowed_workspaces" "eks" {
  agent_pool_id = data.tfe_agent_pool.aws.id
  allowed_workspace_ids = [
    data.tfe_workspace.eks.id,
  ]
}

resource "tfe_agent_token" "agent01" {
  agent_pool_id = data.tfe_agent_pool.aws.id
  description   = "Agent 1"
}

data "cloudinit_config" "agent" {
  gzip          = false
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      = <<-EOF
      #!/bin/bash
      sudo apt update && sudo apt -y upgrade 
      sudo apt install -y unzip
      curl -o tfc-agent.zip -X GET https://releases.hashicorp.com/tfc-agent/1.15.0/tfc-agent_1.15.0_linux_amd64.zip
      unzip tfc-agent.zip
      TFC_AGENT_TOKEN=${tfe_agent_token.agent01.token} ./tfc-agent
    EOF
  }
}

resource "aws_security_group" "tfc_agents" {
  name        = "tfc-agents"
  description = "Security group for Terraform Cloud agents"
  vpc_id      = aws_vpc.this.id

  egress {
    description = "Allow outbound HTTP to the internet (apt install)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound HTTPS to the internet (TFC)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic to same subnet"
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = [
      aws_subnet.private01.cidr_block,
      aws_subnet.private02.cidr_block,
      aws_subnet.private03.cidr_block,
    ]
  }

  egress {
    description = "Allow outbound to HCP Vault"
    from_port   = 8200
    to_port     = 8200
    protocol    = "tcp"
    cidr_blocks = [
      hcp_hvn.this.cidr_block,
    ]
  }

  tags = {
    Name = "Terraform Cloud Agent"
  }
}

data "aws_ami" "ubuntu_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical account ID
}

resource "aws_instance" "agent" {
  ami                    = data.aws_ami.ubuntu_ami.id
  instance_type          = var.aws_instance_type
  key_name               = aws_key_pair.ec2.key_name
  vpc_security_group_ids = [aws_security_group.tfc_agents.id]
  subnet_id              = aws_subnet.private01.id
  availability_zone      = data.aws_availability_zones.available.names[0]

  user_data_base64            = data.cloudinit_config.agent.rendered
  associate_public_ip_address = false

  tags = {
    Name = "Terraform Cloud Agent 1"
  }
}
