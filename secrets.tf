# 1. Create a random password generator
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "_!%^" 
}

# 2. Creating the secret "container" in AWS Secrets Manager
resource "aws_secretsmanager_secret" "db_secret" {
  name        = "${var.project_name}-db-password-v2" # Unique name
  description = "Password for n8n PostgreSQL database"
  recovery_window_in_days = 0 # Deletes immediately if the infrastructure is destroyed (save money)
}

# 3. Inserting the random password into the container
resource "aws_secretsmanager_secret_version" "db_password_val" {
  secret_id     = aws_secretsmanager_secret.db_secret.id
  secret_string = random_password.db_password.result
}