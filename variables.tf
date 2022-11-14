variable "app_prefix" {
  description = "Application prefix for the AWS services that are built"
  default = "Order"
}

variable "stage_name" {
  default = "dev"
  type    = "string"
}

variable "region" {
  default = "eu-west-1"
  type    = "string"
}

variable "domain_name" {
  default = "example.com"
  type    = "string"
}

variable "lambda_source_zip_path" {
  description = "Java lambda zip"
  default = "../"
}
