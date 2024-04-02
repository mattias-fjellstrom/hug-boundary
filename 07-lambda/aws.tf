data "aws_iam_policy_document" "vault_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["${data.tfe_outputs.boundary.values.iam_user_vault.arn}"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "vault_invokefunction" {
  statement {
    effect = "Allow"

    actions = [
      "lambda:InvokeFunctionUrl"
    ]

    resources = [
      aws_lambda_function.this.arn,
    ]
  }
}

resource "aws_iam_role" "lambda" {
  name               = "vault-lambda"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.vault_assume_role.json

  inline_policy {
    name   = "lambda"
    policy = data.aws_iam_policy_document.vault_invokefunction.json
  }
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "src/index.mjs"
  output_path = "lambda.zip"
}

resource "aws_lambda_function" "this" {
  function_name    = "boundary-target"
  description      = "A public Lambda function with IAM authentication"
  role             = aws_iam_role.iam_for_lambda.arn
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
}

resource "aws_lambda_function_url" "this" {
  function_name      = aws_lambda_function.this.function_name
  authorization_type = "AWS_IAM"
}
