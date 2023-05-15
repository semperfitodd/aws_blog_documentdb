resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = "prod"
  description = "${var.environment} API deployment"
}

resource "aws_api_gateway_integration" "posts_id_integration" {
  for_each = local.cors_configurations

  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.posts_id.id
  http_method             = aws_api_gateway_method.posts_id_method[each.key].http_method
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.backend.invoke_arn
  integration_http_method = "POST"
}

resource "aws_api_gateway_integration" "posts_integration" {
  for_each = local.cors_configurations

  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.posts.id
  http_method             = aws_api_gateway_method.posts_method[each.key].http_method
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.backend.invoke_arn
  integration_http_method = "POST"
}

resource "aws_api_gateway_integration" "posts_options" {
  for_each = local.cors_configurations

  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.posts.id
  http_method = aws_api_gateway_method.posts_options[each.key].http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = <<EOF
  {
    "statusCode": 200
  }
  EOF
  }
}

resource "aws_api_gateway_integration_response" "posts_options" {
  for_each = local.cors_configurations

  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.posts.id
  http_method = aws_api_gateway_method.posts_options[each.key].http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'${each.key}'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,PUT,DELETE,OPTIONS'"
    "method.response.header.Access-Control-Allow-Headers" = "'${join(",", each.value.allowed_headers)}'"
  }

  response_templates = {
    "application/json" = <<EOF
  {}
  EOF
  }
}

resource "aws_api_gateway_integration_response" "two_hundred" {
  for_each = local.cors_configurations

  depends_on  = [aws_api_gateway_integration.posts_integration]
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.posts.id
  http_method = aws_api_gateway_method.posts_method[each.key].http_method
  status_code = aws_api_gateway_method_response.two_hundred[each.key].status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'${each.key}'"
  }
}

resource "aws_api_gateway_integration_response" "two_hundred_id" {
  for_each = local.cors_configurations

  depends_on  = [aws_api_gateway_integration.posts_id_integration]
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.posts_id.id
  http_method = aws_api_gateway_method.posts_id_method[each.key].http_method
  status_code = aws_api_gateway_method_response.two_hundred_id[each.key].status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'${each.key}'"
  }
}

resource "aws_api_gateway_method" "posts_id_method" {
  for_each = local.cors_configurations

  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.posts_id.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "posts_method" {
  for_each = local.cors_configurations

  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.posts.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "posts_options" {
  for_each = local.cors_configurations

  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.posts.id
  http_method   = "OPTIONS"
  authorization = "NONE"

  request_parameters = {
    "method.request.header.Access-Control-Allow-Headers" = true
    "method.request.header.Access-Control-Allow-Methods" = true
    "method.request.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_method_response" "posts_options" {
  for_each = local.cors_configurations

  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.posts.id
  http_method = aws_api_gateway_method.posts_options[each.key].http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Headers" = true
  }
}

resource "aws_api_gateway_method_response" "two_hundred" {
  for_each = local.cors_configurations

  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.posts.id
  http_method = aws_api_gateway_method.posts_method[each.key].http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_method_response" "two_hundred_id" {
  for_each = local.cors_configurations

  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.posts_id.id
  http_method = aws_api_gateway_method.posts_id_method[each.key].http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_resource" "posts" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "posts"
}

resource "aws_api_gateway_resource" "posts_id" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_resource.posts.id
  path_part   = "{id}"
}

resource "aws_api_gateway_rest_api" "this" {
  name        = var.environment
  description = "API for CRUD operations on MongoDB"

  tags = var.tags
}

resource "aws_lambda_permission" "this" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.backend.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_deployment.this.execution_arn}/*/*"
}