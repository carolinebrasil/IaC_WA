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

### > Security groups
resource "aws_security_group" "web-out" {
  name        = "web-out"
  description = "Allow HTTP inbound traffic"
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

  tags = {
    "Name" = "${var.name_prefix}-web-out"
  }
}

resource "aws_security_group" "sg_web" {
  name        = "sg_web"
  description = "Security group for web app"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    description     = "Ports to sg web app (in)"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.web-out.id]
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

resource "aws_security_group" "sg_lb1" {
  name        = "sg_lb1"
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



### Autoscaling ____________________________________________________________________________________
resource "aws_autoscaling_group" "iac_scaling_group" {
  name                = "iac-asg"
  min_size            = 1
  max_size            = 3
  desired_capacity    = 1
  health_check_type   = "ELB"
  enabled_metrics     = ["GroupMinSize", "GroupMaxSize", "GroupDesiredCapacity", "GroupInServiceInstances", "GroupTotalInstances"]
  metrics_granularity = "1Minute"
  vpc_zone_identifier = [
    aws_subnet.pub-subnet[0].id,
    aws_subnet.pub-subnet[1].id,
    aws_subnet.pub-subnet[2].id
  ]

  target_group_arns   = [aws_lb_target_group.iac_target_group.arn]
  launch_template {
    id      = aws_launch_template.iac_web.id
    version = "$Latest"
  }

  depends_on = [
    aws_lb.iac_lb1,
    aws_launch_template.iac_web
  ]

  tag {
    key                 = "Name"
    value               = "${var.name_prefix}-scaling-group"
    propagate_at_launch = true
  }
}

# ### > Autoscaling policies
# resource "aws_autoscaling_policy" "asg-policy-out" {
#   name                   = "${var.name_prefix}-asg-policy-out"
#   adjustment_type        = "ChangeInCapacity"
#   scaling_adjustment     = 1
#   cooldown               = 300
#   autoscaling_group_name = aws_autoscaling_group.iac_scaling_group.name
# }

# resource "aws_autoscaling_policy" "asg-policy_in" {
#   name                   = "${var.name_prefix}-asg-policy-in"
#   adjustment_type        = "ChangeInCapacity"
#   scaling_adjustment     = -1
#   cooldown               = 300
#   autoscaling_group_name = aws_autoscaling_group.iac_scaling_group.name
# }

## > Launch template

resource "aws_launch_template" "iac_web" {
  description            = "iac_web_template"
  name                   = "iac_web_instance"
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

### Load balancer ____________________________________________________________________________________
resource "aws_lb" "iac_lb1" {
  name               = "iac-lb1"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.sg_lb1.id]
  
  subnets = [
    aws_subnet.pub-subnet[0].id,
    aws_subnet.pub-subnet[1].id,
    aws_subnet.pub-subnet[2].id
  ]

  enable_deletion_protection = false

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

### > Target group
resource "aws_lb_target_group" "iac_target_group" {
  name        = "iac-target-group"
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc.id

  health_check {
    protocol            = "HTTP"
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 30
    interval            = 60
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    "Name" = "${var.name_prefix}-target-group"
  }
}

resource "aws_lb_target_group_attachment" "iac_target_group_at" {
  count            = 1
  target_group_arn = aws_lb_target_group.iac_target_group.arn
  target_id        = aws_launch_template.iac_web.id #aws_instance.iac_web_instance[count.index].id
  port             = 80

  depends_on = [
    aws_launch_template.iac_web
  ]
}



### CloudWatch alarms ____________________________________________________________________________________
# resource "aws_cloudwatch_metric_alarm" "cpualarm" {
#   metric_name         = "CPUUtilization"
#   alarm_name          = "iac-alarm"
#   namespace           = "AWS/EC2"
#   evaluation_periods  = "2"
#   period              = "120"
#   threshold           = "60"
#   statistic           = "Average"
#   comparison_operator = "GreaterThanOrEqualToThreshold"

#   dimensions = {
#     AutoScalingGroupName = "${aws_autoscaling_group.iac_scaling_group.name}"
#   }

#   alarm_description = "This metric monitor ec2 instance cpu"
#   alarm_actions     = ["${aws_autoscaling_policy.asg-policy-out.arn}"]
# }