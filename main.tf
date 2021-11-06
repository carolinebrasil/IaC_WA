### Provider ____________________________________________________________________________________

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      description = "aws_community_day_demo_2021"
      webinar     = "5_pilares_WA"
      # date = "06_11_2021"
    }
  }
}

terraform {
  required_version = ">= 0.13"

  backend "s3" {
    bucket = "willoverwritten"
    key    = "willoverwritten"

    encrypt = true
  }
}

### Compute ____________________________________________________________________________________
resource "aws_key_pair" "iac_key_pair" {
  key_name   = "iac_key_pair"
  public_key = file("${var.key_path}")
}

# resource "aws_instance" "iac_web_instance" {
#   count                  = var.item_count
#   ami                    = var.ami
#   instance_type          = var.instance_type
#   availability_zone      = var.az_names[count.index]
#   vpc_security_group_ids = [aws_security_group.sg_web.id]
#   subnet_id              = aws_subnet.pub-subnet[count.index].id
#   user_data              = file("hello-world-iac-wa.sh")

#   tags = {
#     "Name" = "${var.name_prefix}-iac-web-${count.index}"
#   }
# }
## > Launch template
resource "aws_launch_template" "iac_web" {
  description            = "iac_web_template"
  name                   = "iac_web_tmplt"
  image_id               = var.ami
  instance_type          = var.instance_type
  key_name               = aws_key_pair.iac_key_pair.key_name
  vpc_security_group_ids = ["${aws_security_group.sg_web.id}"]
  user_data = filebase64("hello-world-iac-wa.sh") #filebase64(file("./content/hello-world-iac-wa.sh"))
  #security_group_names = ["${aws_security_group.sg_web.name}"]
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    "Name" = "${var.name_prefix}-launch-tmpt"
  }
}

### > Security groups
resource "aws_security_group" "sg_lb1" {
  name        = "sg_lb1"
  description = "SG - Allow HTTP inbound from interwebs"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    description = "HTTP from VPC"
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
  lifecycle {
    create_before_destroy = true
  }

  tags = {
    "Name" = "${var.name_prefix}-sg-lb1"
  }
}

resource "aws_security_group" "sg_web" {
  name        = "sg_web"
  description = "SG - Allow HTTP inbound for web app (instances)"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    description     = "Ports to sg web app (in)"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_lb1.id]
  }
  egress {
    description = "Ports to sg web app (out)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    "Name" = "${var.name_prefix}-sg-web"
  }
}



resource "aws_security_group_rule" "ssh" {
  security_group_id = aws_security_group.sg_web.id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

### CloudWatch alarms ____________________________________________________________________________________
resource "aws_cloudwatch_metric_alarm" "cpualarm" {
  metric_name         = "CPUUtilization"
  alarm_name          = "iac-alarm"
  namespace           = "AWS/EC2"
  evaluation_periods  = "2"
  period              = "120"
  threshold           = "60"
  statistic           = "Average"
  comparison_operator = "GreaterThanOrEqualToThreshold"

  dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.iac_scaling_group.name}"
  }

  alarm_description = "This metric monitor ec2 instance cpu"
  alarm_actions     = ["${aws_autoscaling_policy.asg-policy-out.arn}"]
}