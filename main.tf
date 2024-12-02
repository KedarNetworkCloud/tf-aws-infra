data "aws_caller_identity" "current" {}

provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}


resource "aws_vpc" "main_vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "KedarMainVPC" // This uses the VPC name from our .tfvars file. This is the name that would show up in the AWS console.
  }
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.public_subnet_cidr_1
  availability_zone = var.subnet_1_zone

  tags = {
    Name = "Public Subnet 1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.public_subnet_cidr_2
  availability_zone = var.subnet_2_zone

  tags = {
    Name = "Public Subnet 2"
  }
}

resource "aws_subnet" "public_subnet_3" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.public_subnet_cidr_3
  availability_zone = var.subnet_3_zone

  tags = {
    Name = "Public Subnet 3"
  }
}

// Create Private Subnets
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.private_subnet_cidr_1
  availability_zone = var.subnet_1_zone

  tags = {
    Name = "Private Subnet 1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.private_subnet_cidr_2
  availability_zone = var.subnet_2_zone

  tags = {
    Name = "Private Subnet 2"
  }
}

resource "aws_subnet" "private_subnet_3" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.private_subnet_cidr_3
  availability_zone = var.subnet_3_zone

  tags = {
    Name = "Private Subnet 3"
  }
}

// Create an Internet Gateway
resource "aws_internet_gateway" "internetGateway" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "Internet Gateway"
  }
}

// Create a public route table
resource "aws_route_table" "publicRouteTable" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internetGateway.id
  }

  tags = {
    Name = "Public Route Table"
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip" {
  depends_on = [aws_internet_gateway.internetGateway]

  tags = {
    Name = "NATGatewayEIP"
  }
}


# NAT Gateway in Public Subnet
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet_1.id

  tags = {
    Name = "NATGateway"
  }
}


resource "aws_route_table_association" "public_subnet_association_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.publicRouteTable.id
}

resource "aws_route_table_association" "public_subnet_association_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.publicRouteTable.id
}

resource "aws_route_table_association" "public_subnet_association_3" {
  subnet_id      = aws_subnet.public_subnet_3.id
  route_table_id = aws_route_table.publicRouteTable.id
}

resource "aws_route_table" "privateRouteTable" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name = "Private Route Table"
  }
}

resource "aws_route_table_association" "private_subnet_association_1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.privateRouteTable.id
}

resource "aws_route_table_association" "private_subnet_association_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.privateRouteTable.id
}

resource "aws_route_table_association" "private_subnet_association_3" {
  subnet_id      = aws_subnet.private_subnet_3.id
  route_table_id = aws_route_table.privateRouteTable.id
}

# Get the public IP address dynamically
data "http" "my_ip" {
  url = "http://checkip.amazonaws.com/"
}

# Application Security Group
resource "aws_security_group" "application_security_webapp_kedar" {
  name        = "application_security_group"
  description = "Security group for web application instances"
  vpc_id      = aws_vpc.main_vpc.id

  # Allow all outgoing traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "application security group"
  }
}

# Security Group Rule for Load Balancer
resource "aws_security_group_rule" "allow_lb_to_webapp" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  security_group_id        = aws_security_group.application_security_webapp_kedar.id
  source_security_group_id = aws_security_group.load_balancer_sg.id
}

# Security Group Rule for SSH access (if needed for debugging)
resource "aws_security_group_rule" "allow_ssh_access" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.application_security_webapp_kedar.id
  cidr_blocks       = ["${chomp(data.http.my_ip.response_body)}/32"]

}


# S3 Bucket resource
resource "aws_s3_bucket" "demo_s3_bucket" {
  bucket = "demo-s3-bucket-${uuid()}" # Use UUID function for uniqueness

  tags = {
    Name = "DemoS3Bucket"
  }
}

# Server-side encryption configuration for the S3 bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "demo_s3_bucket_encryption" {
  bucket = aws_s3_bucket.demo_s3_bucket.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3_key.arn
    }
  }
}



resource "aws_s3_bucket_lifecycle_configuration" "lifecycle_rule" {
  bucket = aws_s3_bucket.demo_s3_bucket.id

  rule {
    id     = "TransitionToIA"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
}

resource "aws_iam_role" "ec2_s3_access_role" {
  name = "EC2S3AccessRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "s3_access_policy" {
  name        = "S3AccessPolicy"
  description = "Allows access to the demo S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:DeleteObject", # Allows deletion of objects
          "s3:DeleteBucket"  # Allows deletion of the bucket itself
        ]
        Resource = [
          aws_s3_bucket.demo_s3_bucket.arn,
          "${aws_s3_bucket.demo_s3_bucket.arn}/*"
        ]
      }
    ]
  })
}

# Policy for CloudWatch logging and metrics
resource "aws_iam_policy" "cloudwatch_policy" {
  name        = "CloudWatchPolicy"
  description = "Allows EC2 instances to write logs and metrics to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy" "ec2_sns_publish_policy" {
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : "sns:Publish",
        "Resource" : aws_sns_topic.user_creation_topic.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_s3_policy" {
  policy_arn = aws_iam_policy.s3_access_policy.arn
  role       = aws_iam_role.ec2_s3_access_role.name
}

resource "aws_iam_role_policy_attachment" "attach_cloudwatch_policy" {
  policy_arn = aws_iam_policy.cloudwatch_policy.arn
  role       = aws_iam_role.ec2_s3_access_role.name
}

resource "aws_iam_role_policy_attachment" "attach_sns_policy" {
  policy_arn = aws_iam_policy.ec2_sns_publish_policy.arn
  role       = aws_iam_role.ec2_s3_access_role.name
}


# Create an EC2 Instance
resource "aws_iam_instance_profile" "ec2_s3_instance_profile" {
  name = "EC2S3InstanceProfile"
  role = aws_iam_role.ec2_s3_access_role.name
}


# Launch Template for EC2 Instances
resource "aws_launch_template" "kedar_web_app_template" {
  name        = "kedar-web-app-launch-template"
  description = "Launch template for Kedar's web application"

  image_id      = var.Kedar_AMI_ID
  instance_type = "t2.micro"
  key_name      = "AWSDEMOROLESSH"

  # Network settings
  network_interfaces {
    associate_public_ip_address = true
    subnet_id                   = aws_subnet.public_subnet_1.id
    security_groups             = [aws_security_group.application_security_webapp_kedar.id]
  }

  # IAM instance profile configuration
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_s3_instance_profile.name
  }

  # Root volume configuration
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 25
      volume_type           = "gp2"
      delete_on_termination = true
      encrypted             = true
      kms_key_id            = aws_kms_key.ec2_key.arn
    }
  }

  # User data (using Secrets Manager for sensitive data)
  user_data = base64encode(templatefile("./ec2InstanceUserData.sh", {
    DB_HOST         = aws_db_instance.kedar_rds_instance.endpoint,
    DB_HOST_NO_PORT = replace(aws_db_instance.kedar_rds_instance.endpoint, ":5432", ""),
    DB_PASSWORD     = jsondecode(data.aws_secretsmanager_secret_version.db_secret_value.secret_string)["DB_PASSWORD"], # Retrieve password from secret
    DB_NAME         = var.RDS_INSTANCE_DB_NAME,
    DB_USERNAME     = var.RDS_INSTANCE_USERNAME,
    S3_BUCKET_NAME  = aws_s3_bucket.demo_s3_bucket.bucket,
    aws_region      = var.aws_region,
    SNS_TOPIC_ARN   = aws_sns_topic.user_creation_topic.arn
  }))


  # Tags
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "KedarWebAppInstance"
    }
  }

  # Optional dependency to ensure Secrets Manager is set up before this template
  depends_on = [
    aws_db_instance.kedar_rds_instance,
    aws_secretsmanager_secret_version.db_credentials_version
  ]
}


# RDS Subnet Group for Private Subnet 1 only
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "kedar-rds-subnet-group"
  subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id] # Use only Private Subnet 1

  tags = {
    Name = "KedarRDSSubnetGroup"
  }
}

# Security Group for RDS
resource "aws_security_group" "rds_security_group" {
  name        = "kedar-rds-sg"
  description = "Allow access to RDS from web app"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port       = 5432 # Replace with 3306 for MySQL
    to_port         = 5432 # Replace with 3306 for MySQL
    protocol        = "tcp"
    security_groups = [aws_security_group.application_security_webapp_kedar.id] # Allow traffic from EC2 instances only
  }

  ingress {
    from_port       = 5432 # Replace with 3306 for MySQL
    to_port         = 5432 # Replace with 3306 for MySQL
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "RDS Security Group"
  }
}

# Create RDS parameter group for PostgreSQL 15
resource "aws_db_parameter_group" "db_parameter_group" {
  name   = "custom-postgres-parameter-group"
  family = "postgres15" # Update this based on your PostgreSQL version

  # Disable SSL enforcement
  parameter {
    name  = "rds.force_ssl"
    value = "0"
  }


  tags = {
    Name = "custom-postgres-parameter-group"
  }
}

# Reference the existing Route 53 hosted zone in the main AWS account
data "aws_route53_zone" "demo" {
  name = "demo.csye6225kedar.xyz"
}

resource "aws_route53_record" "dns_record" {
  zone_id = data.aws_route53_zone.demo.zone_id
  name    = "${var.DEMO_SUBDOMAIN_NAME}.${var.MAIN_DOMAIN_NAME}"
  type    = "A"

  alias {
    name                   = aws_lb.app_load_balancer.dns_name
    zone_id                = aws_lb.app_load_balancer.zone_id
    evaluate_target_health = true
  }
}


# Create RDS instance with encryption and Secrets Manager for password
resource "aws_db_instance" "kedar_rds_instance" {
  identifier             = var.RDS_INSTANCE_IDENTIFIER # Unique identifier for the RDS instance
  engine                 = var.RDS_INSTANCE_ENGINE     # Database engine
  engine_version         = var.RDS_INSTANCE_ENGINE_VERSION
  instance_class         = var.RDS_INSTANCE_INSTANCE_CLASS            # Instance type
  allocated_storage      = 20                                         # Amount of storage in GB
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name  # Subnet group for RDS instance
  vpc_security_group_ids = [aws_security_group.rds_security_group.id] # Security group attached to the instance
  publicly_accessible    = false                                      # Set to true if accessible from the internet
  skip_final_snapshot    = true                                       # Skip final snapshot on deletion
  db_name                = var.RDS_INSTANCE_DB_NAME

  username = var.RDS_INSTANCE_USERNAME # Database username
  password = random_password.db_password.result

  # Use the custom KMS key for encryption
  storage_encrypted = true
  kms_key_id        = aws_kms_key.rds_key.arn # KMS key for encrypting the RDS instance

  # Use the correct attribute for parameter group
  parameter_group_name = aws_db_parameter_group.db_parameter_group.name

  tags = {
    Name = "KedarRDSInstance"
  }
}


# Load Balancer Security Group
resource "aws_security_group" "load_balancer_sg" {
  name        = "load_balancer_security_group"
  description = "Security group for the load balancer"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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


# Step 5: Application Load Balancer

resource "aws_lb" "app_load_balancer" {
  name               = "app-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load_balancer_sg.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id, aws_subnet.public_subnet_3.id]

  enable_deletion_protection = false
}

# HTTPS Listener for Load Balancer
resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.app_load_balancer.arn
  port              = 443
  protocol          = "HTTPS"

  # Specify the SSL certificate ARN you just imported
  #certificate_arn   = "arn:aws:acm:us-east-1:043309350711:certificate/9f7117d7-9900-4dc4-9244-e8c41f8e2f6e"  # Use your CertificateArn here
  certificate_arn = var.SSL_CERTIFICATE_ARN
  # Optional: You can define the SSL policy as per your requirements
  ssl_policy = "ELBSecurityPolicy-2016-08"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_target_group.arn
  }
}


# Target Group for Load Balancer
resource "aws_lb_target_group" "app_target_group" {
  name     = "app-target-group"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main_vpc.id

  health_check {
    path                = "/healthz"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_autoscaling_group" "kedar_web_app_asg" {
  launch_template {
    id      = aws_launch_template.kedar_web_app_template.id
    version = "$Latest"
  }

  min_size         = 1
  max_size         = 1
  desired_capacity = 1
  vpc_zone_identifier = [
    aws_subnet.public_subnet_1.id
  ]

  # Link the Auto Scaling Group to the Target Group
  target_group_arns = [aws_lb_target_group.app_target_group.arn]

  # Add tags to the Auto Scaling Group
  tag {
    key                 = "AutoScalingGroup"
    value               = "csye6225_asg"
    propagate_at_launch = true
  }

  # Specify other necessary settings (like health check type, etc.)
  health_check_type         = "EC2"
  health_check_grace_period = 300

  # Specify a name for the ASG
  name = "kedar-web-app-asg"
}


# Auto Scaling Policies
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "ScaleUpPolicy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = aws_autoscaling_group.kedar_web_app_asg.name
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "ScaleDownPolicy"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = aws_autoscaling_group.kedar_web_app_asg.name
}

# CloudWatch Metric Alarms for Scaling Policies
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name                = "High CPU Alarm"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "2"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "60"
  statistic                 = "Average"
  threshold                 = 12.0 # CPU utilization threshold for scaling out
  alarm_description         = "Alarm when CPU exceeds 5%"
  insufficient_data_actions = []
  alarm_actions             = [aws_autoscaling_policy.scale_up.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.kedar_web_app_asg.name
  }
}

resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name                = "Low CPU Alarm"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = "2"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "60"
  statistic                 = "Average"
  threshold                 = 8.0 # CPU utilization threshold for scaling in
  alarm_description         = "Alarm when CPU goes below 3%"
  insufficient_data_actions = []
  alarm_actions             = [aws_autoscaling_policy.scale_down.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.kedar_web_app_asg.name
  }
}

resource "aws_lambda_layer_version" "send_email_dependencies" {
  layer_name          = "send-email-dependencies"
  compatible_runtimes = ["nodejs18.x"]
  s3_bucket           = aws_s3_bucket.lambda_bucket.bucket
  s3_key              = aws_s3_object.lambda_layer_zip.key
}

resource "aws_lambda_function" "send_email" {
  s3_bucket     = aws_s3_bucket.lambda_bucket.bucket
  s3_key        = aws_s3_object.lambda_function_zip.key
  function_name = "SendEmailFunction"
  handler       = "sendEmail.handler"
  runtime       = "nodejs18.x"
  timeout       = 120
  role          = aws_iam_role.lambda_exec.arn # Specify the role here

  layers = [aws_lambda_layer_version.send_email_dependencies.arn]

  # VPC Configuration
  vpc_config {
    subnet_ids         = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id] # Private subnets where RDS resides
    security_group_ids = [aws_security_group.lambda_sg.id]                                # Security group attached to Lambda
  }
}



# Lambda Security Group
resource "aws_security_group" "lambda_sg" {
  vpc_id = aws_vpc.main_vpc.id

  # Outbound rule to allow HTTPS traffic on port 443 to SendGrid API or any external service
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
  }

  # Egress rule to allow outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound rule for specific access (e.g., RDS security group access)
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.2.0/24"] # RDS private subnet CIDR
  }

  tags = {
    Name = "LambdaSecurityGroup"
  }
}


resource "aws_iam_role" "lambda_exec" {
  name = "lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}


resource "aws_iam_policy" "rds_access_policy" {
  name        = "rds-access-policy"
  description = "Policy to allow Lambda to describe and connect to RDS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "rds:DescribeDBInstances"
        Resource = "arn:aws:rds:us-east-1:123456789012:db:kedar_rds_instance"
      },
      {
        Effect   = "Allow"
        Action   = "rds-db:connect"
        Resource = "arn:aws:rds-db:us-east-1:123456789012:dbuser:kedar_rds_instance/kedaruser"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_rds_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.rds_access_policy.arn
}


resource "aws_iam_role_policy_attachment" "lambda_exec_cloudwatch" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_sns_topic" "user_creation_topic" {
  name = "user-creation-topic"
}

resource "aws_sns_topic_subscription" "sns_lambda_subscription" {
  topic_arn = aws_sns_topic.user_creation_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.send_email.arn
}


resource "aws_lambda_permission" "allow_sns_to_invoke_lambda" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.send_email.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.user_creation_topic.arn
}

resource "aws_iam_policy" "lambda_vpc_policy" {
  name        = "LambdaVPCPolicy"
  description = "Policy that allows Lambda functions to create network interfaces in VPC"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_exec_vpc_policy_attachment" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_vpc_policy.arn
}


resource "aws_s3_bucket" "lambda_bucket" {
  bucket = "demo-s3-bucket-${uuid()}" # The S3 bucket name

  tags = {
    Name        = "Lambda Bucket"
    Environment = "Production"
  }
}

resource "aws_s3_object" "lambda_layer_zip" {
  bucket = aws_s3_bucket.lambda_bucket.bucket                                # References the S3 bucket name defined above
  key    = "lambda-layer.zip"                                                # File name directly in S3 root
  source = "C:\\Users\\kedar\\Music\\LAMBDAFOLDERSFORASS8\\lambda-layer.zip" # Full path to the ZIP file
  //etag   = filemd5("C:\\Users\\kedar\\Music\\LAMBDAFOLDERSFORASS8\\lambda-layer.zip") # Ensures updates only if the file changes
}

resource "aws_s3_object" "lambda_function_zip" {
  bucket = aws_s3_bucket.lambda_bucket.bucket                              # References the S3 bucket name defined above
  key    = "serverless.zip"                                                # File name directly in S3 root
  source = "C:\\Users\\kedar\\Music\\LAMBDAFOLDERSFORASS8\\serverless.zip" # Full path to the ZIP file
  //etag   = filemd5("C:\\Users\\kedar\\Music\\LAMBDAFOLDERSFORASS8\\serverless.zip") # Ensures updates only if the file changes
}

resource "aws_kms_key" "ec2_key" {
  description             = "KMS key for EC2"
  enable_key_rotation     = true
  rotation_period_in_days = 90
}


resource "aws_kms_key" "rds_key" {
  description             = "KMS key for RDS"
  enable_key_rotation     = true
  rotation_period_in_days = 90
}

resource "aws_kms_key" "s3_key" {
  description             = "KMS key for S3 Buckets"
  enable_key_rotation     = true
  rotation_period_in_days = 90
}

resource "aws_kms_key" "secrets_key" {
  description             = "KMS key for Secrets Manager"
  enable_key_rotation     = true
  rotation_period_in_days = 90
}

# Random password for the database
resource "random_password" "db_password" {
  length  = 16
  special = false
}

# Database Secret: Store all DB credentials in one secret
resource "aws_secretsmanager_secret" "db_credentials" {
  name       = "db_credentials"
  kms_key_id = aws_kms_key.secrets_key.id
}

resource "aws_secretsmanager_secret_version" "db_credentials_version" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    DB_HOST         = aws_db_instance.kedar_rds_instance.endpoint,
    DB_HOST_NO_PORT = replace(aws_db_instance.kedar_rds_instance.endpoint, ":5432", ""),
    DB_PASSWORD     = random_password.db_password.result,
    DB_NAME         = var.RDS_INSTANCE_DB_NAME,
    DB_USERNAME     = var.RDS_INSTANCE_USERNAME
  })
}

# Email Service Secret
resource "aws_secretsmanager_secret" "email_credentials" {
  name       = "email_service_credentials"
  kms_key_id = aws_kms_key.secrets_key.id
}

resource "aws_secretsmanager_secret_version" "email_secret_version" {
  secret_id     = aws_secretsmanager_secret.email_credentials.id
  secret_string = var.SENDGRID_API_KEY
}

# Fetch the latest version of DB credentials (for example usage)
data "aws_secretsmanager_secret_version" "db_secret_value" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  depends_on = [
    aws_secretsmanager_secret_version.db_credentials_version
  ]
}

# Secret for DOMAIN
resource "aws_secretsmanager_secret" "domain_secret" {
  name       = "domain_secret"
  kms_key_id = aws_kms_key.secrets_key.id
}

resource "aws_secretsmanager_secret_version" "domain_secret_version" {
  secret_id     = aws_secretsmanager_secret.domain_secret.id
  secret_string = var.DEMO_DOMAIN
}


resource "aws_iam_policy" "lambda_secrets_policy" {
  name        = "lambda-secrets-access-policy"
  description = "Policy to allow Lambda access to Secrets Manager and decrypt using a customer-managed KMS key"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "secretsmanager:GetSecretValue"
        Resource = [
          aws_secretsmanager_secret.db_credentials.arn,
          aws_secretsmanager_secret.email_credentials.arn,
          aws_secretsmanager_secret.domain_secret.arn
        ]
      },
      {
        Effect   = "Allow"
        Action   = "kms:Decrypt"
        Resource = aws_kms_key.secrets_key.arn # Decrypt permission for the customer-managed KMS key
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "attach_lambda_secrets_policy" {
  policy_arn = aws_iam_policy.lambda_secrets_policy.arn
  role       = aws_iam_role.lambda_exec.name
}


resource "aws_iam_policy" "ec2_secrets_access_policy" {
  name        = "EC2SecretsManagerAccessPolicy"
  description = "Policy to allow EC2 to access Secrets Manager for RDS credentials and decrypt using a customer-managed KMS key"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        Resource = aws_secretsmanager_secret.db_credentials.arn
      },
      {
        Effect   = "Allow",
        Action   = "kms:Decrypt",
        Resource = aws_kms_key.secrets_key.arn # Decrypt permission for the custom KMS key used for secrets
      },
      {
        Effect   = "Allow",
        Action   = "kms:Decrypt",
        Resource = aws_kms_key.ec2_key.arn # Decrypt permission for the KMS key used for EBS volume encryption
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "attach_secrets_policy_to_ec2" {
  role       = aws_iam_role.ec2_s3_access_role.name
  policy_arn = aws_iam_policy.ec2_secrets_access_policy.arn
}


resource "aws_kms_key_policy" "rds_key_policy" {
  key_id = aws_kms_key.rds_key.id
  policy = jsonencode({
    "Id" : "key-for-ebs",
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "Enable IAM User Permissions",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        "Action" : "kms:*",
        "Resource" : "*"
      },
      {
        "Sid" : "Allow access for Key Administrators",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
        },
        "Action" : [
          "kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:Revoke*",
          "kms:Disable*",
          "kms:Get*",
          "kms:Delete*",
          "kms:TagResource",
          "kms:UntagResource",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "Allow use of the key",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
        },
        "Action" : [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        "Resource" : "*"
      }
    ]
  })
}
resource "aws_kms_key_policy" "ec2_kms_key_policy" {
  key_id = aws_kms_key.ec2_key.key_id
  policy = jsonencode({
    "Id" : "key-for-ebs",
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "Enable IAM User Permissions",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        "Action" : "kms:*",
        "Resource" : "*"
      },
      {
        "Sid" : "Allow access for Key Administrators",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
        },
        "Action" : [
          "kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:Revoke*",
          "kms:Disable*",
          "kms:Get*",
          "kms:Delete*",
          "kms:TagResource",
          "kms:UntagResource",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "Allow use of the key",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
        },
        "Action" : [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "Allow attachment of persistent resources",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
        },
        "Action" : [
          "kms:CreateGrant",
          "kms:ListGrants",
          "kms:RevokeGrant"
        ],
        "Resource" : "*",
        "Condition" : {
          "Bool" : {
            "kms:GrantIsForAWSResource" : "true"
          }
        }
      }
    ]
  })
}


resource "aws_kms_key_policy" "secret_manager_key_policy" {
  key_id = aws_kms_key.secrets_key.id
  policy = jsonencode({
    "Id" : "key-for-ebs",
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "Enable IAM User Permissions",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        "Action" : "kms:*",
        "Resource" : "*"
      },
      {
        "Sid" : "Allow access for Key Administrators",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
        },
        "Action" : [
          "kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:Revoke*",
          "kms:Disable*",
          "kms:Get*",
          "kms:Delete*",
          "kms:TagResource",
          "kms:UntagResource",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "Allow use of the key",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
        },
        "Action" : [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_kms_key_policy" "s3_key_policy" {
  key_id = aws_kms_key.s3_key.id
  policy = jsonencode({
    "Id" : "key-for-ebs",
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "Enable IAM User Permissions",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        "Action" : "kms:*",
        "Resource" : "*"
      },
      {
        "Sid" : "Allow access for Key Administrators",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
        },
        "Action" : [
          "kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:Revoke*",
          "kms:Disable*",
          "kms:Get*",
          "kms:Delete*",
          "kms:TagResource",
          "kms:UntagResource",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "Allow use of the key",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
        },
        "Action" : [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        "Resource" : "*"
      }
    ]
  })
}


