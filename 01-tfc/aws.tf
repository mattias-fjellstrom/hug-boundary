# IAM ------------------------------------------------------------------------------------------------------------------
resource "aws_iam_user" "hug" {
  name = "hug"
  path = "/"
}

resource "aws_iam_access_key" "hug" {
  user = aws_iam_user.hug.name
}

data "aws_iam_policy" "admin" {
  name = "AdministratorAccess"
}

resource "aws_iam_user_policy_attachment" "admin" {
  user       = aws_iam_user.hug.name
  policy_arn = data.aws_iam_policy.admin.arn
}

# ECR ------------------------------------------------------------------------------------------------------------------
resource "aws_ecr_repository" "boundary" {
  name = "boundary-worker"
}

data "aws_caller_identity" "me" {}

data "aws_iam_policy_document" "container_registry" {
  statement {
    sid    = "container-registry"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.me.account_id]
    }

    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeRepositories",
      "ecr:GetRepositoryPolicy",
      "ecr:ListImages",
      "ecr:DeleteRepository",
      "ecr:BatchDeleteImage",
      "ecr:SetRepositoryPolicy",
      "ecr:DeleteRepositoryPolicy",
    ]
  }
}

resource "aws_ecr_repository_policy" "boundary" {
  repository = aws_ecr_repository.boundary.name
  policy     = data.aws_iam_policy_document.container_registry.json
}
