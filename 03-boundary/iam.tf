# AWS LAMBDA <-> VAULT INTERACTION -------------------------------------------------------------------------------------
resource "aws_iam_user" "vault" {
  name = "vault"
  path = "/"
}

resource "aws_iam_access_key" "vault" {
  user = aws_iam_user.vault.name
}

# NOTE: this _should_ be restricted, but OK for demo
resource "aws_iam_user_policy" "vault" {
  name   = "VaultLambdaPolicy"
  user   = aws_iam_user.vault.name
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

# EC2 DYNAMIC HOST DISCOVERY -------------------------------------------------------------------------------------------
resource "aws_iam_user" "boundary" {
  name = "boundary"
  path = "/"
}

resource "aws_iam_access_key" "boundary" {
  user = aws_iam_user.boundary.name
}

resource "aws_iam_user_policy" "BoundaryDescribeInstances" {
  name   = "BoundaryDescribeInstances"
  user   = aws_iam_user.boundary.name
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:DescribeInstances"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

# WORKERS IAM INSTANCE PROFILE -----------------------------------------------------------------------------------------
data "aws_iam_policy_document" "workers_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_s3_bucket" "session_recording" {
  bucket = data.tfe_outputs.platform.values.aws_s3_bucket.bucket
}

data "aws_iam_policy_document" "s3" {
  statement {
    effect = "Allow"

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectAttributes",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]

    resources = [
      "arn:aws:s3:::${data.tfe_outputs.platform.values.aws_s3_bucket.bucket}/*",
      "arn:aws:s3:::${data.tfe_outputs.platform.values.aws_s3_bucket.bucket}",
    ]
  }
}

resource "aws_iam_role" "workers" {
  name               = "boundary-workers"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.workers_assume_role.json

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/CloudWatchAgentAdminPolicy",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
  ]

  inline_policy {
    name   = "s3"
    policy = data.aws_iam_policy_document.s3.json
  }
}

resource "aws_iam_instance_profile" "workers" {
  name = "boundary-worker-instance-profile"
  role = aws_iam_role.workers.name
}
