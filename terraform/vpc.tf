module "glue_vpc" {
  source = "github.com/cds-snc/terraform-modules//vpc?ref=v10.2.0"
  name   = "glue-${var.env}"

  enable_flow_log                  = true
  availability_zones               = 2
  cidrsubnet_newbits               = 8
  single_nat_gateway               = true
  allow_https_request_out          = true
  allow_https_request_out_response = true
  allow_https_request_in           = true
  allow_https_request_in_response  = true

  billing_tag_value = var.billing_code
}

#
# VPC Endpoints
#

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = module.glue_vpc.vpc_id
  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.${var.region}.secretsmanager"
  private_dns_enabled = true
  security_group_ids = [
    aws_security_group.privatelink.id,
  ]
  subnet_ids = module.glue_vpc.private_subnet_ids
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id              = module.glue_vpc.vpc_id
  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.${var.region}.logs"
  private_dns_enabled = true
  security_group_ids = [
    aws_security_group.privatelink.id,
  ]
  subnet_ids = module.glue_vpc.private_subnet_ids
}

resource "aws_vpc_endpoint" "monitoring" {
  vpc_id              = module.glue_vpc.vpc_id
  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.${var.region}.monitoring"
  private_dns_enabled = true
  security_group_ids = [
    aws_security_group.privatelink.id,
  ]
  subnet_ids = module.glue_vpc.private_subnet_ids
}

resource "aws_vpc_endpoint" "rds" {
  vpc_id              = module.glue_vpc.vpc_id
  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.${var.region}.rds-data"
  private_dns_enabled = true
  security_group_ids = [
    aws_security_group.privatelink.id,
  ]
  subnet_ids = module.glue_vpc.private_subnet_ids
}

resource "aws_vpc_endpoint" "glue" {
  vpc_id              = module.glue_vpc.vpc_id
  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.${var.region}.glue"
  private_dns_enabled = true
  security_group_ids = [
    aws_security_group.privatelink.id,
  ]
  subnet_ids = module.glue_vpc.private_subnet_ids
}


resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.glue_vpc.vpc_id
  vpc_endpoint_type = "Gateway"
  service_name      = "com.amazonaws.${var.region}.s3"
  route_table_ids   = [module.glue_vpc.main_route_table_id]
}

#
# Security groups
#

# Glue
resource "aws_security_group" "glue_job" {
  description = "NSG for glue ECS Tasks"
  name        = "glue_job"
  vpc_id      = module.glue_vpc.vpc_id
}

resource "aws_security_group_rule" "glue_job_egress_s3" {
  type              = "egress"
  protocol          = "-1"
  to_port           = 443
  from_port         = 443
  security_group_id = aws_security_group.glue_job.id
  prefix_list_ids = [aws_vpc_endpoint.s3.prefix_list_id]
}

# A requirement for the Glue SG to allow all ingress/egress
resource "aws_security_group_rule" "glue_job_egress_all" {
  type              = "egress"
  protocol          = "tcp"
  to_port           = 65535
  from_port         = 0
  security_group_id = aws_security_group.glue_job.id
  self              = true
}

resource "aws_security_group_rule" "glue_job_ingress_all" {
  type              = "ingress"
  protocol          = "tcp"
  to_port           = 65535
  from_port         = 0
  security_group_id = aws_security_group.glue_job.id
  self              = true
}

resource "aws_security_group_rule" "glue_job_egress_db" {
  description              = "Egress from glue job to database"
  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.glue_job.id
  source_security_group_id = aws_security_group.glue_db.id
}

resource "aws_security_group_rule" "glue_job_egress_privatelink" {
  description              = "Egress from glue job to privatelink"
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.glue_job.id
  source_security_group_id = aws_security_group.privatelink.id
}

# Database
resource "aws_security_group" "glue_db" {
  name        = "glue_db"
  description = "NSG for glue database"
  vpc_id      = module.glue_vpc.vpc_id
}

resource "aws_security_group_rule" "glue_db_ingress_job" {
  description              = "Ingress from glue job to database"
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.glue_db.id
  source_security_group_id = aws_security_group.glue_job.id
}

resource "aws_security_group_rule" "glue_db_egress_privatelink" {
  description              = "Egress from glue database to privatelink"
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.glue_db.id
  source_security_group_id = aws_security_group.privatelink.id
}

# Private endpoints
resource "aws_security_group" "privatelink" {
  name        = "privatelink"
  description = "Privatelink endpoints"
  vpc_id      = module.glue_vpc.vpc_id
}

resource "aws_security_group_rule" "glue_job_ingress_privatelink" {
  description              = "Security group rule for Glue job ingress"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.privatelink.id
  source_security_group_id = aws_security_group.glue_job.id
}

resource "aws_security_group_rule" "glue_db_ingress_privatelink" {
  description              = "Security group rule for Glue DB ingress"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.privatelink.id
  source_security_group_id = aws_security_group.glue_db.id
}