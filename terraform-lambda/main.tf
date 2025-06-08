provider "aws" {
  region = var.region
}

# IAM Role for Lambda with Amazon Bedrock Full Access + Admin + Logging
resource "aws_iam_role" "lambda_exec" {
  name = "lambda-bedrock-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# Attach required policies
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "bedrock_full" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonBedrockFullAccess"
}

resource "aws_iam_role_policy_attachment" "admin_access" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Zip Lambda code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda.zip"
}

# Lambda Function definition
resource "aws_lambda_function" "bedrock_lambda" {
  function_name = "bedrock-lambda-handler"
  role          = aws_iam_role.lambda_exec.arn
  runtime       = "python3.11"
  handler       = "main.lambda_handler"  # main.py -> def lambda_handler()

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = 603    # 10 minutes + 3 seconds
  memory_size      = 128
}
