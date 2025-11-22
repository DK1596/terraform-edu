variable "server_port" {
  description = "Server port Instance"
  type = number
  default = 8080
}

variable "aws_sg_instance" {
  description = "Name of SG for Instance"
  type = string
  default = "terr-sg-ex-instance"
}

variable "aws_sg_lb" {
  description = "Name of SG for ALB"
  type = string
  default = "terr-sg-ex-lb"
}