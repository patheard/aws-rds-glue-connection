resource "aws_glue_security_configuration" "encryption_at_rest" {
  name = "encryption-at-rest"

  encryption_configuration {
    cloudwatch_encryption {
      cloudwatch_encryption_mode = "SSE-KMS"
      kms_key_arn                = aws_kms_key.aws_glue.arn
    }

    job_bookmarks_encryption {
      job_bookmarks_encryption_mode = "CSE-KMS"
      kms_key_arn                   = aws_kms_key.aws_glue.arn
    }

    s3_encryption {
      s3_encryption_mode = "SSE-S3"
    }
  }
}

# CloudWatch logging
resource "aws_cloudwatch_log_group" "glue_log_group" {
  name              = "/aws-glue/jobs/error-logs"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_stream" "glue_log_stream" {
  name           = "rds_glue_job_error_log_stream"
  log_group_name = aws_cloudwatch_log_group.glue_log_group.name
}

# Database connection
resource "aws_glue_connection" "rds_postgres" {
  name            = "glue-database"
  connection_type = "JDBC"

  connection_properties = {
    JDBC_CONNECTION_URL = "jdbc:postgresql://${module.glue_db.rds_cluster_endpoint}:5432/glue"
    SECRET_ID           = aws_secretsmanager_secret.rds_connector.name
  }

  physical_connection_requirements {
    availability_zone      = local.rds_cluster_instance_az
    security_group_id_list = [aws_security_group.glue_job.id]
    subnet_id              = local.rds_cluster_instance_subnet_id[0]
  }
}

# Glue job
data "local_file" "glue_script" {
  filename = "${path.module}/scripts/rds_etl.py"
}

resource "aws_s3_object" "glue_script" {
  bucket = module.etl_bucket.s3_bucket_id
  key    = "rds_etl.py"
  source = data.local_file.glue_script.filename
  etag   = filemd5(data.local_file.glue_script.filename)
}

resource "aws_glue_job" "rds_glue_job" {
  name         = "rds_glue_job"
  role_arn     = aws_iam_role.glue_etl.arn
  connections  = [aws_glue_connection.rds_postgres.name]
  glue_version = "5.0"

  command {
    script_location = "s3://${aws_s3_object.glue_script.bucket}/${aws_s3_object.glue_script.key}"
    python_version  = "3"
  }

  default_arguments = {
    "--continuous-log-logGroup"          = aws_cloudwatch_log_group.glue_log_group.name
    "--continuous-log-logStreamPrefix"   = aws_cloudwatch_log_stream.glue_log_stream.name
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-continuous-log-filter"     = "true"
    "--enable-metrics"                   = "true"
    "--enable-observability-metrics"     = "true"
    "--rds_connection_name"              = aws_glue_connection.rds_postgres.name
  }
  security_configuration = aws_glue_security_configuration.encryption_at_rest.name
}
