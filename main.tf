terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# =====================================================================
# VPC
# =====================================================================

resource "aws_vpc" "my-vpc" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  tags = {
    owner = var.owner
  }
}

resource "aws_internet_gateway" "my-gw" {
  vpc_id = aws_vpc.my-vpc.id
}

resource "aws_route_table" "my-route-table" {
  vpc_id = aws_vpc.my-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my-gw.id
  }
}

resource "aws_subnet" "public-subnet1a" {
  vpc_id                  = aws_vpc.my-vpc.id
  map_public_ip_on_launch = true
  cidr_block              = var.subnet_prefix-az1[0]
  availability_zone       = var.availability_zone[0]
}
resource "aws_route_table_association" "public-a" {
  subnet_id      = aws_subnet.public-subnet1a.id
  route_table_id = aws_route_table.my-route-table.id
}

resource "aws_subnet" "public-subnet1b" {
  vpc_id                  = aws_vpc.my-vpc.id
  map_public_ip_on_launch = true
  cidr_block              = var.subnet_prefix-az2[0]
  availability_zone       = var.availability_zone[1]
}
resource "aws_route_table_association" "public-b" {
  subnet_id      = aws_subnet.public-subnet1b.id
  route_table_id = aws_route_table.my-route-table.id
}


# =====================================================================
# ASG + ALB
# =====================================================================
# 1) ami
data "aws_ami" "amazon-linux-2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

# 3) security group for ec2
resource "aws_security_group" "web-ec2" {
  name   = "web-ec2-sg"
  vpc_id = aws_vpc.my-vpc.id
  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.admin
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 4) Launch Configuration
resource "aws_launch_configuration" "web-ec2" {
  name_prefix     = "web-ec2-asg-"
  image_id        = data.aws_ami.amazon-linux-2.id
  instance_type   = var.web_ec2_type
  security_groups = [aws_security_group.web-ec2.id]
  key_name        = "tursunbekova-key"

  lifecycle {
    create_before_destroy = true
  }
}

# 5) asg 
resource "aws_autoscaling_group" "web-ec2" {
  name                 = "web-ec2"
  min_size             = 2
  max_size             = 6
  desired_capacity     = 2
  launch_configuration = aws_launch_configuration.web-ec2.name
  vpc_zone_identifier  = [aws_subnet.public-subnet1a.id, aws_subnet.public-subnet1b.id]

  tag {
    key                 = "owner"
    value               = var.owner
    propagate_at_launch = true
  }
  tag {
    key                 = "type"
    value               = "web-ec2"
    propagate_at_launch = true
  }
}

# 6) web lb

resource "aws_security_group" "web_lb" {
  name = "web_lb-sg"
  vpc_id = aws_vpc.my-vpc.id
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

resource "aws_lb" "web-lb" {
  name               = "web-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_lb.id]
  subnets            = [aws_subnet.public-subnet1a.id, aws_subnet.public-subnet1b.id]
}

resource "aws_lb_listener" "web-lb" {
  load_balancer_arn = aws_lb.web-lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web-tg.arn
  }
}

resource "aws_lb_target_group" "web-tg" {
  name     = "web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.my-vpc.id
}

resource "aws_autoscaling_attachment" "web" {
  autoscaling_group_name = aws_autoscaling_group.web-ec2.id
  alb_target_group_arn   = aws_lb_target_group.web-tg.arn
}
