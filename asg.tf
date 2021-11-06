
### Autoscaling ____________________________________________________________________________________
resource "aws_autoscaling_group" "iac_scaling_group" {
  name                      = "iac-asg"
  min_size                  = 1
  desired_capacity          = 2
  max_size                  = 4
  health_check_type         = "ELB"
  health_check_grace_period = "300"
  enabled_metrics           = ["GroupMinSize", "GroupMaxSize", "GroupDesiredCapacity", "GroupInServiceInstances", "GroupTotalInstances"]
  metrics_granularity       = "1Minute"
  vpc_zone_identifier = [
    aws_subnet.pub-subnet[0].id,
    aws_subnet.pub-subnet[1].id,
    aws_subnet.pub-subnet[2].id
  ]

  launch_template {
    id      = aws_launch_template.iac_web.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.iac_target_group.arn]


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
