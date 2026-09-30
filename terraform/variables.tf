variable "aws_region" { type = string, default = "ap-south-1" }
variable "project_name" { type = string, default = "ecommerce-devsecops" }
variable "vpc_cidr" { type = string, default = "10.20.0.0/16" }
variable "db_username" { type = string, default = "ecommerce_admin" }
variable "db_password" { type = string, sensitive = true }
variable "state_bucket_name" { type = string, description = "Globally unique S3 bucket for remote state; created separately." }
