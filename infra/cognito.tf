# # Crear el User Pool de Cognito (gestión de usuarios)
# resource "aws_cognito_user_pool" "flavios_user_pool" {
#   name = "flavios-pool"
# }

# # Crear el Identity Pool para obtener credenciales de AWS
# resource "aws_cognito_identity_pool" "flavios_identity_pool" {
#   identity_pool_name               = "flavios-identity-pool"
#   allow_unauthenticated_identities = false

#   cognito_identity_providers {
#     client_id     = aws_cognito_user_pool_client.flavios_user_pool_client.id
#     provider_name = aws_cognito_user_pool.flavios_user_pool.endpoint
#   }
# }

# # Crear un cliente para el User Pool (necesario para autenticar a los usuarios)
# resource "aws_cognito_user_pool_client" "flavios_user_pool_client" {
#   name            = "flavios-user-pool-client"
#   user_pool_id    = aws_cognito_user_pool.flavios_user_pool.id
#   generate_secret = false

#   explicit_auth_flows = [
#     "ALLOW_USER_PASSWORD_AUTH",
#     "ALLOW_REFRESH_TOKEN_AUTH",
#     "ALLOW_USER_SRP_AUTH",
#     "ALLOW_CUSTOM_AUTH"
#   ]
# }