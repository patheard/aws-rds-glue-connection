variable "billing_code" {
  description = "The billing code to use for cost allocation"
  type        = string
}

variable "env" {
  description = "The target environment for the resources"
  type        = string
}

variable "glue_database_password" {
  description = "The password for the glue database"
  type        = string
  sensitive   = true
}

variable "glue_database_username" {
  description = "The username for the glue database"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "The AWS region to deploy resources"
  type        = string
}