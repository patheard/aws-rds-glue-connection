module "etl_bucket" {
  source            = "github.com/cds-snc/terraform-modules//S3?ref=v10.0.0"
  bucket_name       = "aws-rds-glue-connection-etl"
  billing_tag_value = var.billing_code

  versioning = {
    enabled = true
  }
}