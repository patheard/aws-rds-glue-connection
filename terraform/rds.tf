#
# RDS Postgress cluster
#
module "glue_db" {
  source = "github.com/cds-snc/terraform-modules//rds?ref=v10.2.0"
  name   = "glue-${var.env}"

  database_name  = "glue"
  engine         = "aurora-postgresql"
  engine_version = "15.5"
  instances      = 1
  instance_class = "db.serverless"
  username       = var.glue_database_username
  password       = var.glue_database_password
  use_proxy      = false

  backup_retention_period      = 14
  preferred_backup_window      = "02:00-04:00"
  performance_insights_enabled = true

  serverless_min_capacity = 1
  serverless_max_capacity = 2

  vpc_id             = module.glue_vpc.vpc_id
  subnet_ids         = module.glue_vpc.private_subnet_ids
  security_group_ids = [aws_security_group.glue_db.id]

  billing_tag_value = var.billing_code
}

resource "aws_secretsmanager_secret" "rds_connector" {
  name = "rds-connector-${var.env}"
}

resource "aws_secretsmanager_secret_version" "rds_connector" {
  secret_id = aws_secretsmanager_secret.rds_connector.id
  secret_string = jsonencode({
    username = var.glue_database_username
    password = var.glue_database_password
  })
}

