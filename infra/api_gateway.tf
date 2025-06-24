# Crear el API Gateway
resource "aws_api_gateway_rest_api" "flavios_api" {
  name        = "flavios-api"
  description = "API con autenticación Cognito"
}

# Crear el Authorizer Cognito en API Gateway
resource "aws_api_gateway_authorizer" "flavios_cognito_authorizer" {
  name            = "FlaviosCognitoAuthorizer"
  rest_api_id     = aws_api_gateway_rest_api.flavios_api.id
  identity_source = "method.request.header.Authorization"
  provider_arns   = [aws_cognito_user_pool.flavios_user_pool.arn]
  type            = "COGNITO_USER_POOLS"
}

# Crear el recurso de la API (/data) ruta o endpoint
resource "aws_api_gateway_resource" "flavios_data_resource" {
  rest_api_id = aws_api_gateway_rest_api.flavios_api.id
  parent_id   = aws_api_gateway_rest_api.flavios_api.root_resource_id
  path_part   = "data"
}

# Crear el recurso de la API (/message) ruta o endpoint
resource "aws_api_gateway_resource" "flavios_message_resource" {
  rest_api_id = aws_api_gateway_rest_api.flavios_api.id
  parent_id   = aws_api_gateway_rest_api.flavios_api.root_resource_id
  path_part   = "message"
}

# Crear el método POST para la API Gateway, data
resource "aws_api_gateway_method" "post_data_method" {
  rest_api_id   = aws_api_gateway_rest_api.flavios_api.id
  resource_id   = aws_api_gateway_resource.flavios_data_resource.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.flavios_cognito_authorizer.id
}
# Crear el método POST para la API Gateway, message
resource "aws_api_gateway_method" "post_message_method" {
  rest_api_id   = aws_api_gateway_rest_api.flavios_api.id
  resource_id   = aws_api_gateway_resource.flavios_message_resource.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.flavios_cognito_authorizer.id
}

# Crear la integración Lambda para la API Gateway data
resource "aws_api_gateway_integration" "post_data_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.flavios_api.id
  resource_id             = aws_api_gateway_resource.flavios_data_resource.id
  http_method             = aws_api_gateway_method.post_data_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:us-east-2:lambda:path/2015-03-31/functions/${aws_lambda_function.post_data_lambda.arn}/invocations"
}

# Crear la integración Lambda para la API Gateway message
resource "aws_api_gateway_integration" "post_message_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.flavios_api.id
  resource_id             = aws_api_gateway_resource.flavios_message_resource.id
  http_method             = aws_api_gateway_method.post_message_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:us-east-2:lambda:path/2015-03-31/functions/${aws_lambda_function.post_message_lambda.arn}/invocations"
}

# Activar permisos para la API Gateway para invocar la Lambda data
resource "aws_lambda_permission" "api_gateway_permission_post_data" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.post_data_lambda.function_name
  principal     = "apigateway.amazonaws.com"
}

# Activar permisos para la API Gateway para invocar la Lambda message
resource "aws_lambda_permission" "api_gateway_permission_post_message" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.post_message_lambda.function_name
  principal     = "apigateway.amazonaws.com"
}

# Hacer el deploy de la api
resource "aws_api_gateway_deployment" "flavios_api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.flavios_api.id
  depends_on = [
    aws_api_gateway_integration.post_data_lambda_integration,
    aws_api_gateway_integration.post_message_lambda_integration,
  ]
}

resource "aws_api_gateway_stage" "dev_stage" {
  stage_name    = "dev"
  rest_api_id   = aws_api_gateway_rest_api.flavios_api.id
  deployment_id = aws_api_gateway_deployment.flavios_api_deployment.id

  description = "Development stage"
}