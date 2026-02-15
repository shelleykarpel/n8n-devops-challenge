#!/bin/bash
# 1. Updating the system and installing Docker
apt-get update -y
apt-get install -y docker.io
systemctl start docker
systemctl enable docker

# 2. Running n8n inside Docker
# Connect it to an external Postgres
docker run -d \
  --name n8n \
  --restart always \
  -p 5678:5678 \
  -e N8N_SECURE_COOKIE=false \
  -e DB_TYPE=postgresdb \
  -e DB_POSTGRESDB_DATABASE=n8n \
  -e DB_POSTGRESDB_HOST=${db_endpoint} \
  -e DB_POSTGRESDB_PORT=5432 \
  -e DB_POSTGRESDB_USER=n8n_user \
  -e DB_POSTGRESDB_PASSWORD=${db_password} \
  -e N8N_ENCRYPTION_KEY=my-secret-key-123 \
  n8nio/n8n