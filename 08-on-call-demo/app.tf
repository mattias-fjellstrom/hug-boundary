data "aws_iam_policy_document" "app" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "app" {
  name               = "lambda-app"
  assume_role_policy = data.aws_iam_policy_document.app.json
}

data "archive_file" "app" {
  type        = "zip"
  source_file = "app/index.mjs"
  output_path = "app.zip"
}

resource "aws_lambda_function" "app" {
  function_name    = "app"
  description      = "A simple web app"
  role             = aws_iam_role.app.arn
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  filename         = data.archive_file.app.output_path
  source_code_hash = data.archive_file.app.output_base64sha256
}

resource "aws_lambda_function_url" "app" {
  function_name      = aws_lambda_function.app.function_name
  authorization_type = "NONE"
}
