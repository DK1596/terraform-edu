terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.99.1"
    }
  }

  backend "s3" {
    bucket = "terraform-bucket-test-aws"
    region = "us-east-1"
    key = "stage/data-stores/mysql/terraform.tfstate"

    dynamodb_table = "terraform_dynamo_db_test_aws"
    encrypt = true
  }
}
provider "aws" {
  region = "us-east-1"
}

resource "aws_db_instance" "example" {
  identifier_prefix = "terraform-up-and-running"
  engine = "mysql"
  allocated_storage = 10
  instance_class = "db.t3.micro"
  skip_final_snapshot = true
  db_name = var.db_name

  username = var.db_username
  password = var.db_password
}

