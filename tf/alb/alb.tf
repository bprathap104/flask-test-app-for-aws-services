data "aws_vpc" "selected" {
  id = "vpc-088944afb91b96a4f" # Replace with your VPC ID
}


data "aws_subnets" "available" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
}

# Select the first two subnets from the data source
data "aws_subnet" "selected" {
  count = 6
  id    = data.aws_subnets.available.ids[count.index]
}


# Security group for the load balancer
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Security group for the Application Load Balancer"
  vpc_id      = data.aws_vpc.selected.id
  ingress {
    from_port   = 443
    to_port     = 443
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

# Application Load Balancer
resource "aws_lb" "alb" {
  name               = "my-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.aws_subnet.selected[*].id
}

# Listener for HTTPS traffic
resource "aws_lb_listener" "alb_listener_https" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:us-east-1:058264499673:certificate/c9fef51d-29a9-4961-813b-9bae4b30671e"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group.arn
  }
}

# Target group for the ALB
resource "aws_lb_target_group" "alb_target_group" {
  name        = "alb-target-group"
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.selected.id
  target_type = "instance"

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 10
  }
}

# Attach the EC2 instance to the target group
resource "aws_lb_target_group_attachment" "alb_target_group_attachment" {
  count            = length(data.aws_instances.target_instances.ids)
  target_group_arn = aws_lb_target_group.alb_target_group.arn
  target_id        = data.aws_instances.target_instances.ids[count.index]
  port             = 5000
}

# Data source to fetch instances with the 'Example Instance (Ubuntu)' tag
data "aws_instances" "target_instances" {
  filter {
    name   = "tag:Name"
    values = ["Example Instance (Ubuntu)"]
  }

  instance_state_names = ["running"]
}
