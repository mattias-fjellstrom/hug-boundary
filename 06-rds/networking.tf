resource "aws_db_subnet_group" "this" {
  name        = "aurora-subnet-group"
  description = "For Aurora postgresql serverless cluster"
  subnet_ids = [
    data.tfe_outputs.platform.values.private_subnets[0].id,
    data.tfe_outputs.platform.values.private_subnets[1].id,
    data.tfe_outputs.platform.values.private_subnets[2].id,
  ]

  tags = {
    Name = "Aurora"
  }
}

resource "aws_security_group" "db" {
  name        = "aurora"
  description = "Security group for Aurora postgresql serverless cluster"
  vpc_id      = data.tfe_outputs.platform.values.aws_vpc.id

  // inbound traffic from boundary workers in same subnet
  ingress {
    description = "Allow traffic from same subnet"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [
      data.tfe_outputs.platform.values.private_subnets[0].cidr_block,
      data.tfe_outputs.platform.values.private_subnets[1].cidr_block,
      data.tfe_outputs.platform.values.private_subnets[2].cidr_block,
    ]
  }

  // inbound traffic from hcp vault
  ingress {
    description = "Allow traffic from hcp vault"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [
      data.tfe_outputs.platform.values.hcp_cidr_range
    ]
  }

  tags = {
    Name = "Aurora DB"
  }
}
