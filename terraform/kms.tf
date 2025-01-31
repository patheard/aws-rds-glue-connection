#
# KMS key used by AWS Glue for encryption
#
resource "aws_kms_key" "aws_glue" {
  description         = "AWS Glue encryption key for data at rest"
  enable_key_rotation = "true"
  policy              = data.aws_iam_policy_document.aws_glue.json
}

resource "aws_kms_alias" "data_export" {
  name          = "alias/aws-glue"
  target_key_id = aws_kms_key.aws_glue.key_id
}

data "aws_iam_policy_document" "aws_glue" {
  # Allow this account to use the key
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [local.account_id]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  # Allow CloudWatch Logs to use the key for encryption
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["logs.${var.region}.amazonaws.com"]
    }
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    resources = ["*"]
  }

  # Allow Glue roles to use the key for encryption
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.glue_etl.arn]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:GenerateDataKeyWithoutPlaintext",
      "kms:ReEncryptFrom",
      "kms:ReEncryptTo",
      "kms:CreateGrant",
      "kms:DescribeKey",
      "kms:RetireGrant"
    ]
    resources = ["*"]
  }
}