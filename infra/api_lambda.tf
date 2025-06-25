# Zip lambda source code for post data
data "archive_file" "api_post_data" {
  type        = "zip"
  source_file = "./lambda_scripts/api_post_data.py"
  output_path = "./lambda_outputs/api_post_data.zip"
}

# Create lambda function for post data
resource "aws_lambda_function" "post_data_lambda" {
  function_name    = "api-post-data"
  handler          = "api-post-data.handler"
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
  function_name    = "api-post-message"
  handler          = "api-post-message.handler"
  runtime          = "python3.12"
  role             = aws_iam_role.lambda_api_role.arn 
  filename         = data.archive_file.api_post_message.output_path
  source_code_hash = data.archive_file.api_post_message.output_base64sha256

  environment {
    variables = {
      BUCKET_NAME = "flavios-bucket-ia-caj"
      GEMINI_API_KEY = "AIzaSyDivAocZiirjN4ezRiViEdkh6tWCWSff7Y"
    }
  }
}