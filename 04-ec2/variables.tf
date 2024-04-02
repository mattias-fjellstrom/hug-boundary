variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "eu-west-1"
}

variable "aws_instance_type" {
  type        = string
  description = "EC2 instance type for targets"
  default     = "t2.micro"
}
