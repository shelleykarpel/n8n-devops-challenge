# 1. Defining the location of the DB within our network
resource "aws_db_subnet_group" "n8n_db_subnets" {
  name       = "${var.project_name}-db-subnets"
  subnet_ids = [aws_subnet.public_1.id, aws_subnet.public_2.id]
  tags       = { Name = "${var.project_name}-db-subnet-group" }
}

# 2. Database firewall
resource "aws_security_group" "db_sg" {
  name        = "${var.project_name}-db-sg"
  vpc_id      = aws_vpc.main.id

  # Ingress: Allows traffic on port 5432 only from within our VPC
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 3. Creating the PostgreSQL server itself
resource "aws_db_instance" "n8n_db" {
  allocated_storage    = 20
  db_name              = "n8n"
  engine               = "postgres"
  engine_version       = "14"
  instance_class       = "db.t3.micro" # Cheap and suitable for the task
  username             = "n8n_user"
  
  # Here we use the random password we created in secrets.tf
  password             = random_password.db_password.result
  
  db_subnet_group_name   = aws_db_subnet_group.n8n_db_subnets.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  
  skip_final_snapshot  = true 
  publicly_accessible  = true # Allows me remote access if I want to debug
}