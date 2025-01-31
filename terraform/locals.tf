data "aws_caller_identity" "current" {}

data "aws_db_instance" "rds_instance" {
  db_instance_identifier = "glue-${var.env}-instance-0"

  depends_on = [
    module.glue_db
  ]
}

data "aws_subnet" "private" {
  count = 2
  id    = module.glue_vpc.private_subnet_ids[count.index]

  depends_on = [
    module.glue_vpc
  ]
}

locals {
  account_id = data.aws_caller_identity.current.account_id

  rds_cluster_instance_az         = data.aws_db_instance.rds_instance.availability_zone
  rds_cluster_instance_identifier = data.aws_db_instance.rds_instance.db_instance_identifier
  rds_cluster_instance_subnet_id  = [for subnet in data.aws_subnet.private : subnet.id if subnet.availability_zone == local.rds_cluster_instance_az]
}