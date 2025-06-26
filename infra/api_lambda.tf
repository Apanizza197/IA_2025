# Zip lambda source code for post data
data "archive_file" "api_post_data" {
  type        = "zip"
  source_file = "./lambda_scripts/api_post_data.py"
  output_path = "./lambda_outputs/api_post_data.zip"
}

# Create lambda function for post data
resource "aws_lambda_function" "post_data_lambda" {
  function_name    = "api_post_data"
  handler          = "api_post_data.handler"
  runtime          = "python3.12"
  role             = aws_iam_role.lambda_api_role.arn 
  filename         = data.archive_file.api_post_data.output_path
  source_code_hash = data.archive_file.api_post_data.output_base64sha256

  environment {
    variables = {
      BUCKET_NAME = "NOT YET SET"
    }
  }
}

# Zip lambda source code
data "archive_file" "api_post_message" {
  type        = "zip"
  source_file = "./lambda_scripts/api_post_message.py"
  output_path = "./lambda_outputs/api_post_message.zip"
}

# Create lambda function
resource "aws_lambda_function" "post_message_lambda" {
  function_name    = "api_post_message"
  handler          = "api_post_message.handler"
  runtime          = "python3.12"
  role             = aws_iam_role.lambda_api_role.arn 
  filename         = data.archive_file.api_post_message.output_path
  source_code_hash = data.archive_file.api_post_message.output_base64sha256

  environment {
    variables = {
      BUCKET_NAME = "flavios-bucket-ia-caj"
      GEMINI_API_KEY = "AIzaSyDivAocZiirjN4ezRiViEdkh6tWCWSff7Y"
      TELEGRAM_BOT_TOKEN = "7997151342:AAFmh3OdjoTkLhnTT53euVrmsPWbiKyCS7c"
    }
  }
}

# Zip lambda source code for GET /status
data "archive_file" "api_get_status" {
  type        = "zip"
  source_file = "./lambda_scripts/api_get_status.py"
  output_path = "./lambda_outputs/api_get_status.zip"
}

# Lambda function for GET /status
resource "aws_lambda_function" "get_status_lambda" {
  function_name    = "api_get_status"
  handler          = "api_get_status.handler"
  runtime          = "python3.12"
  role             = aws_iam_role.lambda_api_role.arn 
  filename         = data.archive_file.api_get_status.output_path
  source_code_hash = data.archive_file.api_get_status.output_base64sha256
}
