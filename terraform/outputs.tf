output "api_gateway_invoke_url" {
  value = aws_api_gateway_deployment.this.invoke_url
}

output "url" {
  value = "https://${local.site_domain}"
}