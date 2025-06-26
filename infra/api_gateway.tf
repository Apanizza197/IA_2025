###############################################
# API principal
###############################################
resource "aws_api_gateway_rest_api" "flavios_api" {
  name        = "flavios-api"
}
resource "aws_api_gateway_resource" "flavios_data_resource" {
  rest_api_id = aws_api_gateway_rest_api.flavios_api.id
  parent_id   = aws_api_gateway_rest_api.flavios_api.root_resource_id
  path_part   = "data"
}

resource "aws_api_gateway_resource" "flavios_message_resource" {
  rest_api_id = aws_api_gateway_rest_api.flavios_api.id
  parent_id   = aws_api_gateway_rest_api.flavios_api.root_resource_id
  path_part   = "message"
}

resource "aws_api_gateway_resource" "flavios_status_resource" {
  rest_api_id = aws_api_gateway_rest_api.flavios_api.id
  parent_id   = aws_api_gateway_rest_api.flavios_api.root_resource_id
  path_part   = "status"
}

###############################################
# POST /data
###############################################
resource "aws_api_gateway_method" "post_data_method" {
  rest_api_id   = aws_api_gateway_rest_api.flavios_api.id
  resource_id   = aws_api_gateway_resource.flavios_data_resource.id
  http_method   = "POST"
  authorization = "NONE"      
}

###############################################
# POST /message
###############################################
resource "aws_api_gateway_method" "post_message_method" {
  rest_api_id   = aws_api_gateway_rest_api.flavios_api.id
  resource_id   = aws_api_gateway_resource.flavios_message_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

###############################################
# GET /status
###############################################

resource "aws_api_gateway_method" "get_status_method" {
  rest_api_id   = aws_api_gateway_rest_api.flavios_api.id
  resource_id   = aws_api_gateway_resource.flavios_status_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "post_data_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.flavios_api.id
  resource_id             = aws_api_gateway_resource.flavios_data_resource.id
  http_method             = aws_api_gateway_method.post_data_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${aws_lambda_function.post_data_lambda.arn}/invocations"
}

resource "aws_api_gateway_integration" "post_message_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.flavios_api.id
  resource_id             = aws_api_gateway_resource.flavios_message_resource.id
  http_method             = aws_api_gateway_method.post_message_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${aws_lambda_function.post_message_lambda.arn}/invocations"
}

resource "aws_api_gateway_integration" "get_status_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.flavios_api.id
  resource_id             = aws_api_gateway_resource.flavios_status_resource.id
  http_method             = aws_api_gateway_method.get_status_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${aws_lambda_function.get_status_lambda.arn}/invocations"
}

resource "aws_lambda_permission" "api_gateway_permission_post_data" {
  statement_id  = "AllowAPIGatewayInvokeData"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.post_data_lambda.function_name
  principal     = "apigateway.amazonaws.com"
}

resource "aws_lambda_permission" "api_gateway_permission_post_message" {
  statement_id  = "AllowAPIGatewayInvokeMessage"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.post_message_lambda.function_name
  principal     = "apigateway.amazonaws.com"
}


resource "aws_lambda_permission" "api_gateway_permission_get_status" {
  statement_id  = "AllowAPIGatewayInvokeGetStatus"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_status_lambda.function_name
  principal     = "apigateway.amazonaws.com"
}

resource "aws_api_gateway_deployment" "flavios_api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.flavios_api.id
  depends_on  = [
    aws_api_gateway_integration.post_data_lambda_integration,
    aws_api_gateway_integration.post_message_lambda_integration,
    aws_api_gateway_integration.get_status_lambda_integration,
  ]
}

resource "aws_api_gateway_stage" "dev_stage" {
  stage_name    = "dev"
  rest_api_id   = aws_api_gateway_rest_api.flavios_api.id
  deployment_id = aws_api_gateway_deployment.flavios_api_deployment.id
  description   = "Development stage"
}
