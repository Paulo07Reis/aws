provider "aws" {
  region = "us-east-1"
}

# DynamoDB Table
resource "aws_dynamodb_table" "telemetria" {
  name         = "telemetria_http"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "deviceId"
  range_key    = "ts"

  attribute {
    name = "deviceId"
    type = "S"
  }

  attribute {
    name = "ts"
    type = "N"
  }
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "telemetria-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for DynamoDB Access
resource "aws_iam_role_policy" "lambda_dynamodb_policy" {
  name = "telemetria-lambda-dynamodb-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem"
        ]
        Resource = aws_dynamodb_table.telemetria.arn
      }
    ]
  })
}

# Lambda Function
resource "aws_lambda_function" "telemetria" {
  function_name = "TelemetriaLambda"
  runtime       = "python3.12"
  handler       = "lambda_handler.lambda_handler"
  role          = aws_iam_role.lambda_role.arn

  filename         = "lambda_handler.zip" # pacote com o código Python
  source_code_hash = filebase64sha256("lambda_handler.zip")

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.telemetria.name
    }
  }
}

# API Gateway REST API
resource "aws_api_gateway_rest_api" "telemetria_api" {
  name = "TelemetriaAPI"
}

# Resource /telemetria
resource "aws_api_gateway_resource" "telemetria_resource" {
  rest_api_id = aws_api_gateway_rest_api.telemetria_api.id
  parent_id   = aws_api_gateway_rest_api.telemetria_api.root_resource_id
  path_part   = "telemetria"
}

# Method POST
resource "aws_api_gateway_method" "telemetria_post" {
  rest_api_id   = aws_api_gateway_rest_api.telemetria_api.id
  resource_id   = aws_api_gateway_resource.telemetria_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

# Integration with Lambda (Proxy)
resource "aws_api_gateway_integration" "telemetria_integration" {
  rest_api_id             = aws_api_gateway_rest_api.telemetria_api.id
  resource_id             = aws_api_gateway_resource.telemetria_resource.id
  http_method             = aws_api_gateway_method.telemetria_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.telemetria.invoke_arn
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.telemetria.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.telemetria_api.execution_arn}/*/*"
}

# Deployment + Stage
resource "aws_api_gateway_deployment" "telemetria_deploy" {
  depends_on = [aws_api_gateway_integration.telemetria_integration]

  rest_api_id = aws_api_gateway_rest_api.telemetria_api.id
  stage_name  = "dev"
}

output "invoke_url" {
  value = "${aws_api_gateway_deployment.telemetria_deploy.invoke_url}telemetria"
}
