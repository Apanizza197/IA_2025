# Policies

# Full access permissions for s3
data "aws_iam_policy_document" "s3_full_access" {
  statement {
    actions   = ["s3:GetObject", "s3:ListBucket", "s3:PutObject", "s3:GetObjectTagging"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.flavios_bucket.bucket}/*", "arn:aws:s3:::${aws_s3_bucket.flavios_bucket.bucket}"]
  }
}

resource "aws_iam_policy" "s3_full_access_policy" {
  name   = "s3_full_access_policy_flavio"
  description = "Policy to allow full access to S3 bucket for Lambda functions"
  policy = data.aws_iam_policy_document.s3_full_access.json
}

# Full access permissions for DynamoDB table
data "aws_iam_policy_document" "dynamodb_full_access" {
  statement {
    actions   = ["dynamodb:PutItem", "dynamodb:GetItem", "dynamodb:Scan", "dynamodb:Query"]
    resources = [
        aws_dynamodb_table.flavios_records.arn
    ]
  }
}

resource "aws_iam_policy" "dynamodb_full_access_policy" {
  name   = "dynamodb_full_access_policy"
  description = "Policy to allow full access to DynamoDB table for Lambda functions"
  policy = data.aws_iam_policy_document.dynamodb_full_access.json
}

# IAM Policy for lambda function to access logs
resource "aws_iam_policy" "lambda_logging_policy" {
  name = "prefix_lambda_logging_policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# IAM Policy for lambda function to assume role
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

# API Gateway IAM Role
///////////////////////////////////////////////////
resource "aws_iam_role" "lambda_api_role" {
  name               = "lambda_api_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "lambda_s3_policy_attachment" {
  role       = aws_iam_role.lambda_api_role.name
  policy_arn = aws_iam_policy.s3_full_access_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_logging_attachment" {
  role       = aws_iam_role.lambda_api_role.name
  policy_arn = aws_iam_policy.lambda_logging_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb_policy_attachment" {
  role       = aws_iam_role.lambda_api_role.name
  policy_arn = aws_iam_policy.dynamodb_full_access_policy.arn
}
