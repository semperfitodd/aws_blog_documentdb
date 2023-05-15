module "site" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = local.site_domain

  attach_public_policy = true
  attach_policy        = true
  policy               = data.aws_iam_policy_document.site.json

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  control_object_ownership = true
  object_ownership         = "BucketOwnerPreferred"

  expected_bucket_owner = data.aws_caller_identity.this.account_id

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = var.tags
}

resource "aws_s3_object" "object" {
  bucket = module.site.s3_bucket_id
  content = templatefile("${path.module}/files/index.html.tpl", {
    API_ENDPOINT = aws_api_gateway_deployment.this.invoke_url
    ENVIRONMENT  = var.environment
  })
  content_type = "text/html"
  key          = "index.html"

  tags = var.tags
}