locals {
  availability_zones = [
    data.aws_availability_zones.this.names[0],
    data.aws_availability_zones.this.names[1],
    data.aws_availability_zones.this.names[2],
  ]

  public_subnets = [
    cidrsubnet(local.vpc_cidr, 6, 0),
    cidrsubnet(local.vpc_cidr, 6, 1),
    cidrsubnet(local.vpc_cidr, 6, 2),
  ]

  private_subnets = [
    cidrsubnet(local.vpc_cidr, 6, 4),
    cidrsubnet(local.vpc_cidr, 6, 5),
    cidrsubnet(local.vpc_cidr, 6, 6),
  ]

  database_subnets = [
    cidrsubnet(local.vpc_cidr, 6, 7),
    cidrsubnet(local.vpc_cidr, 6, 8),
    cidrsubnet(local.vpc_cidr, 6, 9),
  ]

  allowed_headers = ["Content-Type", "X-Amz-Date", "Authorization", "X-Api-Key", "X-Amz-Security-Token"]

  allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]

  allowed_origins = ["https://${local.site_domain}"]

  cors_configurations = {
    for origin in local.allowed_origins :
    origin => {
      allowed_methods = local.allowed_methods
      allowed_headers = local.allowed_headers
    }
  }

  environment = replace(var.environment, "_", "-")

  site_domain = "blog.${var.public_domain}"

  vpc_cidr = "10.180.0.0/16"
}