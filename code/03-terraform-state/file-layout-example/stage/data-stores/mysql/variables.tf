variable "db_username" {
  description = "Username for DB"
  type = string
  sensitive = true
}

variable "db_password" {
  description = "Password for DB"
  type = string
  sensitive = true
}

variable "db_name" {
  description = "Name of DB"
  type = string
  default = "example_database_stage"
}