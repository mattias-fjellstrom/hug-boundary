variable "aws_region" {
  description = "AWS region name"
  type        = string
  default     = "eu-west-1"
}

variable "database_name" {
  description = "Name of the main database"
  type        = string
  default     = "hugdb"
}

variable "database_master_username" {
  description = "Master username for the database"
  type        = string
  default     = "postgres"
}
