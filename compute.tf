# Automatically search for the most up-to-date Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # The official Owner ID of Canonical (the creators of Ubuntu)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}


# 1. Creating the Load Balancer (ALB)
resource "aws_lb" "n8n_alb" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]
}

# 2. Defining a Target Group (where the ALB sends the traffic)
resource "aws_lb_target_group" "n8n_tg" {
  name     = "${var.project_name}-tg"
  port     = 5678
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path = "/healthz" # Provides a path to check n8n integrity
  }
}

# 3. Listener - connects the ALB to the Target Group
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.n8n_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.n8n_tg.arn
  }
}

# 4. The "recipe" for the server (Launch Template)
resource "aws_launch_template" "n8n_lt" {
  name_prefix   = "${var.project_name}-lt"
  image_id = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  # Setting up a server as a Spot
  instance_market_options {
    market_type = "spot"
  }

  network_interfaces {
  associate_public_ip_address = true
  security_groups             = [aws_security_group.ec2_sg.id] 
}

  # Script Injection (User Data)
  user_data = base64encode(templatefile("install_n8n.sh", {
    db_endpoint = aws_db_instance.n8n_db.address,
    db_password = random_password.db_password.result
  }))
}

# 5. The "Guardian" (Auto Scaling Group)
resource "aws_autoscaling_group" "n8n_asg" {
  desired_capacity    = 1
  max_size            = 1
  min_size            = 1
  target_group_arns   = [aws_lb_target_group.n8n_tg.arn]
  vpc_zone_identifier = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  launch_template {
    id      = aws_launch_template.n8n_lt.id
    version = "$Latest"
  }
}