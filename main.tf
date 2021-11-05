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

### Compute 
resource "aws_key_pair" "iac_key_pair" {
  key_name   = "iac_key_pair"
  public_key = "${file("${var.key_path}")}"
}
# ### > Launch config
# resource "aws_launch_configuration" "iac_web" {
#   image_id        = var.ami
#   instance_type   = var.instance_type
#   security_groups = ["${aws_security_group.sg_web.id}"]
#   key_name        = aws_key_pair.iac_key_pair.key_name
#   user_data       = "${file("content/hello-world-iac-wa.sh")}"

#   lifecycle {
#     create_before_destroy = true
#   }
# }

### > Launch template

resource "aws_launch_template" "iac_web" {
  description          = ""
  instance_type        = var.instance_type
  image_id             = var.ami
  user_data            = filebase64("hello-world-iac-wa.sh")#filebase64(file("./content/hello-world-iac-wa.sh"))
  key_name             = aws_key_pair.iac_key_pair.key_name
  security_group_names = ["${aws_security_group.sg_web.id}"]
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    "Name" = "${var.name_prefix}-launch-tmpt"
  }
}

### > Target group
resource "aws_lb_target_group" "iac_target_group" {
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
  }

  tags = {
    "Name" = "${var.name_prefix}-target-group"
  }
}

resource "aws_lb_target_group_attachment" "iac_target_group_at" {
  count            = var.item_count
  target_group_arn = aws_lb_target_group.iac_target_group.arn
  target_id        = aws_launch_template.iac_web.id #aws_instance.iac_instance.id
  port             = 80
}

### Autoscaling
resource "aws_autoscaling_group" "iac_scaling_group" {
  availability_zones  = ["us-west-2a", "us-west-2b", "us-west-2c"]
  min_size            = 1
  max_size            = 4
  desired_capacity    = 2
  health_check_type   = "ELB"
  enabled_metrics     = ["GroupMinSize", "GroupMaxSize", "GroupDesiredCapacity", "GroupInServiceInstances", "GroupTotalInstances"]
  metrics_granularity = "1Minute"
  load_balancers      = ["${aws_lb.iac_lb1.id}"]
  launch_template {
    id      = aws_launch_template.iac_web.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.name_prefix}-scaling-group"
    propagate_at_launch = true
  }
}

### > Autoscaling policies
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

### Load balancer
resource "aws_lb" "iac_lb1" {
  internal = false
  subnets = [
    aws_subnet.pub-subnet[0].id,
    aws_subnet.pub-subnet[1].id,
    aws_subnet.pub-subnet[2].id
  ]
  security_groups = [aws_security_group.sg_lb1.id]

  enable_deletion_protection = true

  tags = {
    "Name" = "${var.name_prefix}-lb1"
  }
}

### > LB listener
resource "aws_lb_listener" "iac_lb1_listener" {
  port              = 80
  protocol          = "HTTP"
  load_balancer_arn = aws_lb.iac_lb1.arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.iac_target_group.arn
  }


}
# resource "aws_elb" "iac_elb1" {
#   cross_zone_load_balancing   = true
#   idle_timeout                = 400
#   connection_draining         = true
#   connection_draining_timeout = 400

#   security_groups    = [ aws_security_group.sg_elb1.id ]
#   subnets            = [ 
#     aws_subnet.pub-subnet[0].id, 
#     aws_subnet.pub-subnet[1].id, 
#     aws_subnet.pub-subnet[2].id
#   ]
#   availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]

#   health_check {
#     target              = "HTTP:80/"
#     timeout             = 3
#     interval            = 30
#     healthy_threshold   = 2
#     unhealthy_threshold = 2
#   }

#   listener {
#     instance_port     = 80
#     lb_port           = 80
#     instance_protocol = "http"
#     lb_protocol       = "http"
#   }

#   tags = {
#     "Name" = "${var.name_prefix}-elb1"
#   }
# }

### > Security groups
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

resource "aws_security_group" "sg_lb1" {
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

### CloudWatch alarms
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