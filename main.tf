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

# Compute 
resource "aws_key_pair" "iac_key_pair" {
  key_name   = "iac_key_pair"
  public_key = file("${var.key_path}")
}

resource "aws_launch_configuration" "iac_web" {
  image_id        = var.ami
  instance_type   = var.instance_type
  security_groups = []
  key_name        = aws_key_pair.iac_key_pair.key_name
  user_data       = file("content/hello-world-iac-wa.sh")

  lifecycle {
    create_before_destroy = true
  }
}

# Autoscaling
resource "aws_autoscaling_group" "iac_scaling_group" {
  availability_zones   = ["us-west-2a", "us-west-2b", "us-west-2c"]
  min_size             = 1
  max_size             = 6
  health_check_type    = "ELB"
  enabled_metrics      = ["GroupMinSize", "GroupMaxSize", "GroupDesiredCapacity", "GroupInServiceInstances", "GroupTotalInstances"]
  metrics_granularity  = "1Minute"
  load_balancers       = ["${aws_elb.iac_elb1.id}"]
  launch_configuration = aws_launch_configuration.iac_web.name

  tag {
    key                 = "Name"
    value               = "${var.name_prefix}-scaling-group"
    propagate_at_launch = true
  }
}

# Autoscaling policies
resource "aws_autoscaling_policy" "asg-policy-out" {
  name                   = "${var.name_prefix}-asg-policy-out"
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.iac_scaling_group.name
}

resource "aws_autoscaling_policy" "asg-policy_in" {
  name                   = "${var.name_prefix}-asg-policy-in"
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.iac_scaling_group.name
}

# Load balancer
resource "aws_elb" "iac_elb1" {
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
  security_groups    = ["${aws_security_group.sg_elb1.id}"]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  health_check {
    target              = "HTTP:80/"
    timeout             = 3
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  listener {
    instance_port     = 80
    lb_port           = 80
    instance_protocol = "http"
    lb_protocol       = "http"
  }

  tags = {
    "Name" = "${var.name_prefix}-elb1"
  }
}

# Security groups

resource "aws_security_group" "sg_web" {
  description = "Security group for web app"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    description = "Ports to sg web app (in)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Ports to sg web app (out)"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    "Name" = "${var.name_prefix}-sg-web"
  }
}

resource "aws_security_group" "sg_elb1" {
  description = "Security group for web app"
  vpc_id      = aws_vpc.vpc.id
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
  lifecycle {
    create_before_destroy = true
  }

  tags = {
    "Name" = "${var.name_prefix}-sg-elb1"
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

# CloudWatch alarms

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