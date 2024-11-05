#!/bin/bash
# Update package list
sudo apt-get update -y

# Create the directory for the application if it doesn't exist
sudo mkdir -p /opt/myapp/

# Create .env file with appropriate environment variables
cat <<EOL | sudo tee /opt/myapp/.env
DB_HOST=${DB_HOST_NO_PORT}
DB_NAME=${DB_NAME}
DB_USERNAME=${DB_USERNAME}
DB_PASSWORD=${DB_PASSWORD}
DB_PORT=5432
APP_PORT=8080
S3_BUCKET_NAME=${S3_BUCKET_NAME}
AWS_REGION=${aws_region}
EOL

# Set ownership and permissions for the .env file
sudo chown csye6225:csye6225 /opt/myapp/.env
sudo chmod 644 /opt/myapp/.env

# Create logs directory if it doesn't exist
sudo mkdir -p /opt/myapp/logs

# Create the cloudwatch group and add users
sudo groupadd cloudwatch || true
sudo usermod -aG cloudwatch csye6225
sudo usermod -aG cloudwatch cloudwatch-agent

# Set ownership and permissions for the logs directory
sudo chown -R csye6225:cloudwatch /opt/myapp/logs
sudo chmod -R 775 /opt/myapp/logs
sudo chmod g+s /opt/myapp/logs

# Copy the CloudWatch Agent configuration file to the appropriate location
sudo cp /opt/myapp/config/cloudwatch-config.json /opt/aws/amazon-cloudwatch-agent/etc/

# Reload systemd to recognize new service
sudo systemctl daemon-reload

# Enable and start the web application service
sudo systemctl enable kedarwebapp.service
sudo systemctl start kedarwebapp.service

# Start the CloudWatch Agent using the provided configuration
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/cloudwatch-config.json

# Restart the CloudWatch Agent to apply the new configuration
sudo systemctl restart amazon-cloudwatch-agent