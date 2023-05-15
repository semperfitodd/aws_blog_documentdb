data "aws_availability_zones" "this" {}

data "aws_caller_identity" "this" {}

data "aws_iam_policy_document" "site" {
  statement {
    effect = "Allow"
    principals {
      identifiers = module.cdn.cloudfront_origin_access_identity_iam_arns
      type        = "AWS"
    }
    actions   = ["s3:GetObject"]
    resources = ["${module.site.s3_bucket_arn}/*"]
  }
}

data "aws_route53_zone" "this" {
  name = var.public_domain

  private_zone = false
}