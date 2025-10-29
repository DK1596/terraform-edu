terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.99.1"
    }
  }
}
provider "aws" {
  region = "eu-north-1"
}

// Launch template
resource "aws_launch_template" "template" {
  name_prefix            = "terraform-ex"
  image_id               = "ami-0aa78f446b4499266"
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.instance.id]

  user_data = base64encode(
    <<-EOF
              #!/bin/bash
              mkdir -p /var/www/html
              echo "hello world" > /var/www/html/index.html
              nohup busybox httpd -f -p ${var.server_port} -h /var/www/html &
              EOF
  )

  lifecycle {
    create_before_destroy = true
  }
}

// Auto Scaling Group
resource "aws_autoscaling_group" "example" {
  vpc_zone_identifier = data.aws_subnets.default.ids // по хорошему свой subnets

  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"

  min_size = 2
  max_size = 10

  launch_template {
    id      = aws_launch_template.template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = "terraform-asg-ex"
  }
}

resource "aws_security_group" "instance" {
  name = var.aws_sg_instance

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

// Application Load Balancer
resource "aws_lb" "example" {
  name               = "terraform-asg-ex"
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default.ids // по хорошему свой subnets
  security_groups    = [aws_security_group.alb.id]
}

// Слушает запросы от клиента
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port              = 80
  protocol          = "HTTP"

  // Default Page 404
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

// Отвечает за получения запросов от LB, и состояние Instances
resource "aws_lb_target_group" "asg" {
  name     = "terraform-asg-ex"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

// Отвечает по какому пути отправлять запрос через condition,
// если condition = true идет перенапрвление через action
resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}

resource "aws_security_group" "alb" {
  name = var.aws_sg_lb

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
