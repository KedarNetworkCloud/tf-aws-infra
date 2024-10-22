#!/bin/bash
# Update package list and install required software
sudo apt-get update -y
#sudo apt-get install -y postgresql-client

# Create the directory for the application if it doesn't exist
sudo mkdir -p /opt/myapp/

# Create .env file with appropriate environment variables
cat <<EOL | sudo tee /opt/myapp/.env
DB_HOST=${DB_HOST_NO_PORT}
DB_NAME=csye6225
DB_USERNAME=csye6225
DB_PASSWORD=${DB_PASSWORD}
DB_PORT=5432
APP_PORT=8080
EOL

# Set ownership and permissions for the .env file
sudo chown csye6225:csye6225 /opt/myapp/.env
sudo chmod 644 /opt/myapp/.env

# Reload systemd to recognize new service
sudo systemctl daemon-reload

# Enable and start the web application service
sudo systemctl enable kedarwebapp.service
sudo systemctl start kedarwebapp.service

# Log the status of the service
sudo systemctl status kedarwebapp.service >> /var/log/user_data.log
