variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "eu-west-1"
}

variable "aws_worker_instance_type" {
  type        = string
  description = "EC2 instance type for Boundary workers"
  default     = "t2.micro"
}
