variable "aws_region" {
  description = "The AWS region to deploy in"
  default     = "eu-central-1" 
}

variable "project_name" {
  default     = "n8n-challenge"
}

variable "my_ip" {
  description = "Public IP address for security group whitelisting"
  type        = string
  default     = "0.0.0.0/0" 
}