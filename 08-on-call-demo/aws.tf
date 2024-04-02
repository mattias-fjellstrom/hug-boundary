data "aws_caller_identity" "current" {}

locals {
  function_name = "on-call-alarms"
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

data "aws_iam_policy_document" "cloudwatch" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
    ]
    resources = [
      "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.function_name}:*"
    ]
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "lambda-on-call-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  inline_policy {
    name   = "cloudwatch"
    policy = data.aws_iam_policy_document.cloudwatch.json
  }
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "src/bootstrap"
  output_path = "lambda.zip"
}

resource "aws_lambda_function" "this" {
  function_name    = local.function_name
  description      = "Assign or revoke the on-call role for the on-call user in Boundary"
  role             = aws_iam_role.iam_for_lambda.arn
  handler          = "bootstrap"
  runtime          = "provided.al2023"
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
  architectures    = ["arm64"]
  environment {
    variables = {
      BOUNDARY_ADDR             = data.tfe_outputs.platform.values.boundary_cluster.cluster_url
      BOUNDARY_USERNAME         = boundary_account_password.lambda.login_name
      BOUNDARY_PASSWORD         = boundary_account_password.lambda.password
      BOUNDARY_AUTH_METHOD_ID   = data.boundary_auth_method.password.id
      BOUNDARY_ON_CALL_ROLE_ID  = boundary_role.oncall.id
      BOUNDARY_ON_CALL_GROUP_ID = data.tfe_outputs.boundary.values.boundary_managed_groups["oncall"]
    }
  }
}

resource "aws_lambda_permission" "name" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "lambda.alarms.cloudwatch.amazonaws.com"
}

resource "aws_cloudwatch_metric_alarm" "trigger" {
  actions_enabled           = true
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  alarm_name                = "function-invocation-alarm"
  alarm_description         = "The app Lambda function has many invocations in a short timespan!"
  evaluation_periods        = 1
  datapoints_to_alarm       = 1
  period                    = 60
  statistic                 = "Sum"
  threshold                 = 10
  namespace                 = "AWS/Lambda"
  metric_name               = "Invocations"
  ok_actions                = [aws_lambda_function.this.arn]
  alarm_actions             = [aws_lambda_function.this.arn]
  insufficient_data_actions = [aws_lambda_function.this.arn]
  treat_missing_data        = "notBreaching"
  dimensions = {
    "FunctionName" = aws_lambda_function.app.function_name
  }
}
