data "aws_availability_zones" "this" {}

data "aws_caller_identity" "this" {}

data "aws_route53_zone" "this" {
  name = var.public_domain
}