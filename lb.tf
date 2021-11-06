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
  name        = "iac-tg"
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc.id

  health_check {
    protocol            = "HTTP"
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    "Name" = "${var.name_prefix}-target-group"
  }
}

# resource "aws_lb_target_group_attachment" "iac_target_group_at" {
#   count            = var.item_count
#   target_group_arn = aws_lb_target_group.iac_target_group.arn
#   target_id        = aws_launch_template.iac_web.id
#   #target_id = aws_instance.iac_web_instance[count.index].id
#   port      = 80
# }