#
# Glue ETL role
#
resource "aws_iam_role" "glue_etl" {
  name               = "AWSGlueETL-DataLake"
  path               = "/service-role/"
  assume_role_policy = data.aws_iam_policy_document.glue_assume.json
}

resource "aws_iam_policy" "glue_etl" {
  name   = "AWSGlueETL-DataLake"
  path   = "/service-role/"
  policy = data.aws_iam_policy_document.glue_etl_combined.json
}

data "aws_iam_policy_document" "glue_etl_combined" {
  source_policy_documents = [
    data.aws_iam_policy_document.glue_database_connection.json,
    data.aws_iam_policy_document.glue_kms.json,
    data.aws_iam_policy_document.s3_read_etl_bucket.json
  ]
}

resource "aws_iam_role_policy_attachment" "glue_etl" {
  policy_arn = aws_iam_policy.glue_etl.arn
  role       = aws_iam_role.glue_etl.name
}

resource "aws_iam_role_policy_attachment" "glue_etl_service_role" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
  role       = aws_iam_role.glue_etl.name
}

data "aws_iam_policy_document" "glue_assume" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type = "Service"
      identifiers = [
        "glue.amazonaws.com",
      ]
    }
  }
}

data "aws_iam_policy_document" "s3_read_etl_bucket" {
  statement {
    sid = "ReadDataLakeS3Buckets"
    actions = [
      "s3:GetObject",
    ]
    resources = [
      "${module.etl_bucket.s3_bucket_arn}/*",
    ]
  }
}

data "aws_iam_policy_document" "glue_database_connection" {
  statement {
    sid    = "GetGlueConnection"
    effect = "Allow"
    actions = [
      "glue:GetConnection",
      "glue:GetConnections"
    ]
    resources = [
      aws_glue_connection.rds_postgres.arn
    ]
  }

  statement {
    sid    = "DescribeFormsDBInstances"
    effect = "Allow"
    actions = [
      "rds:DescribeDBInstances"
    ]
    resources = [
      "arn:aws:rds:${var.region}:${local.account_id}:db:${local.rds_cluster_instance_identifier}"
    ]
  }

  statement {
    sid    = "GetRDSConnectorSecret"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]
    resources = [
      aws_secretsmanager_secret.rds_connector.arn
    ]
  }
}

data "aws_iam_policy_document" "glue_kms" {
  statement {
    sid    = "UseGlueKey"
    effect = "Allow"
    actions = [
      "kms:CreateGrant",
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:GenerateDataKeyWithoutPlaintext",
      "kms:ReEncryptFrom",
      "kms:ReEncryptTo",
      "kms:RetireGrant"
    ]
    resources = [
      aws_kms_key.aws_glue.arn
    ]
  }

  statement {
    sid    = "AssociateKmsKey"
    effect = "Allow"
    actions = [
      "logs:AssociateKmsKey"
    ]
    resources = [
      "arn:aws:logs:${var.region}:${local.account_id}:log-group:/aws-glue/crawlers*",
      "arn:aws:logs:${var.region}:${local.account_id}:log-group:/aws-glue/jobs*",
      "arn:aws:logs:${var.region}:${local.account_id}:log-group:/aws-glue/sessions*"
    ]
  }
}
