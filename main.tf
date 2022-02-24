locals {
  name_prefix = substr("${var.cluster_name}-loki", 0, 32)
}

data "aws_iam_policy_document" "aws_loki" {
  statement {
    effect = "Allow"

    actions = [
      "dynamodb:BatchGetItem",
      "dynamodb:BatchWriteItem",
      "dynamodb:DeleteItem",
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:ListTagsOfResource",
      "dynamodb:PutItem",
      "dynamodb:Query",
      "dynamodb:TagResource",
      "dynamodb:UntagResource",
      "dynamodb:UpdateItem",
      "dynamodb:UpdateTable",
      "dynamodb:CreateTable",
      "dynamodb:DeleteTable"
    ]

    resources = [
      "arn:aws:dynamodb:${var.region}:${var.account_id}:table/index*"
    ]
  }
  statement {
    effect = "Allow"

    actions = [
      "dynamodb:ListTables"
    ]

    resources = [
      "*"
    ]
  }
  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:PutObject",
      "s3:ListBucket"
    ]

    resources = [
      "arn:aws:s3:::${var.customer_name}-${var.cluster_name}-loki",
      "arn:aws:s3:::${var.customer_name}-${var.cluster_name}-loki/*"
    ]
  }
}

resource "aws_iam_policy" "aws_loki" {
  name        = local.name_prefix
  description = "loki policy for EKS cluster ${var.cluster_name}"
  policy      = data.aws_iam_policy_document.aws_loki.json
}


module "irsa_aws_loki" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "~> 4.2"

  create_role                   = true
  role_name                     = local.name_prefix
  provider_url                  = var.cluster_oidc_issuer_url
  role_policy_arns              = [aws_iam_policy.aws_loki.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:${var.service_account_namespace}:${var.service_account_name}"]
}

resource "aws_s3_bucket" "aws_loki" {
  bucket = "${var.customer_name}-${var.cluster_name}-loki"
  force_destroy = true

  tags = merge({
    Name = "${var.cluster_name}"
    }, var.tags
  )
}

resource "aws_s3_bucket_versioning" "versioning_loki" {
  bucket = aws_s3_bucket.aws_loki.id
  versioning_configuration {
    status = "Suspended"
  }
}

resource "aws_s3_bucket_acl" "aws_loki" {
  bucket = aws_s3_bucket.aws_loki.id
  acl    = "private"
}

resource "kubernetes_service_account" "sa_loki" {
  automount_service_account_token = true
  metadata {
    annotations = {
      "eks.amazonaws.com/role-arn" = "${module.irsa_aws_loki.iam_role_arn}"
    }
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/name"       = "loki"
    }
    name      = "loki"
    namespace = var.service_account_namespace
  }
  depends_on = [
    module.irsa_aws_loki.id
  ]
}