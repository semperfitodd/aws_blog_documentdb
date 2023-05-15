data "archive_file" "backend" {
  source_dir  = "${path.module}/backend"
  output_path = "backend.zip"
  type        = "zip"
}

data "aws_iam_policy" "AWSLambdaBasicExecutionRole" {
  name = "AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "lambda_execution_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }
  }
}

data "aws_iam_policy_document" "lambda_secret_policy" {
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    effect    = "Allow"
    resources = [aws_secretsmanager_secret.documentdb.arn]
  }
  statement {
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeSubnets",
      "ec2:DescribeVpcs",
    ]
    effect    = "Allow"
    resources = ["*"]
  }
}

resource "aws_iam_policy" "lambda_secret_policy" {
  name = "${var.environment}_lambda_secret_policy"

  policy = data.aws_iam_policy_document.lambda_secret_policy.json

  tags = var.tags
}

resource "aws_iam_role" "lambda_execution_role" {
  name = "${var.environment}_lambda_execution_role"

  assume_role_policy = data.aws_iam_policy_document.lambda_execution_role.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_execution_policy" {
  policy_arn = data.aws_iam_policy.AWSLambdaBasicExecutionRole.arn
  role       = aws_iam_role.lambda_execution_role.name
}

resource "aws_iam_role_policy_attachment" "lambda_secret_policy" {
  policy_arn = aws_iam_policy.lambda_secret_policy.arn
  role       = aws_iam_role.lambda_execution_role.name
}

resource "aws_lambda_function" "backend" {
  description   = "Backend Lambda function to communicate between the API gateway and DocumentDB for the ${var.environment} environment."
  filename      = "backend.zip"
  function_name = "${var.environment}_backend"
  handler       = "backend.handler"
  role          = aws_iam_role.lambda_execution_role.arn
  runtime       = "python3.9"
  timeout       = 30

  vpc_config {
    subnet_ids         = module.vpc.private_subnets
    security_group_ids = [aws_security_group.backend.id]
  }

  environment {
    variables = {
      DOCDB_HOST  = aws_docdb_cluster.documentdb.endpoint
      SECRET_NAME = aws_secretsmanager_secret.documentdb.name
    }
  }

  source_code_hash = data.archive_file.backend.output_base64sha256

  tags = var.tags
}

resource "aws_security_group" "backend" {
  name        = "${local.environment}_backend_lambda"
  description = "Security Group for backend lambda function"
  vpc_id      = module.vpc.vpc_id
  tags        = var.tags
}

resource "aws_security_group_rule" "backend_egress" {
  type              = "egress"
  description       = "Allow all egress traffic"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.backend.id
}

resource "aws_security_group_rule" "backend_ingress" {
  type              = "ingress"
  description       = "Allow inbound traffic from VPC CIDR"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  security_group_id = aws_security_group.backend.id

  cidr_blocks = [module.vpc.vpc_cidr_block]
}