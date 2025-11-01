variable "s3_bucket_name" {
  description = "Global name of bucket"
  type = string
  default = "terr-state-example-demo-test"
}

variable "dynamodb_name" {
  description = "Table name of Dynamo DB"
  type = string
  default = "terraform-state-locks"
}