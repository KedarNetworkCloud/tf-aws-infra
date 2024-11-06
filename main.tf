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



resource "aws_s3_bucket" "demo_s3_bucket" {
  bucket = "demo-s3-bucket-${uuid()}" # Use UUID function for uniqueness

  tags = {
    Name = "DemoS3Bucket"
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

resource "aws_iam_role_policy_attachment" "attach_s3_policy" {
  policy_arn = aws_iam_policy.s3_access_policy.arn
  role       = aws_iam_role.ec2_s3_access_role.name
}

resource "aws_iam_role_policy_attachment" "attach_cloudwatch_policy" {
  policy_arn = aws_iam_policy.cloudwatch_policy.arn
  role       = aws_iam_role.ec2_s3_access_role.name
}


# Create an EC2 Instance
resource "aws_iam_instance_profile" "ec2_s3_instance_profile" {
  name = "EC2S3InstanceProfile"
  role = aws_iam_role.ec2_s3_access_role.name
}


# Launch Template for EC2 instances
resource "aws_launch_template" "kedar_web_app_template" {
  name        = "kedar-web-app-launch-template"
  description = "Launch template for Kedar's web application"

  # Basic instance settings
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
    }
  }

  # User data
  user_data = base64encode(templatefile("./ec2InstanceUserData.sh", {
    DB_HOST         = aws_db_instance.kedar_rds_instance.endpoint
    DB_HOST_NO_PORT = replace(aws_db_instance.kedar_rds_instance.endpoint, ":5432", "")
    DB_PASSWORD     = var.RDS_INSTANCE_KEDAR_PASSWORD
    DB_NAME         = var.RDS_INSTANCE_DB_NAME
    DB_USERNAME     = var.RDS_INSTANCE_USERNAME
    S3_BUCKET_NAME  = aws_s3_bucket.demo_s3_bucket.bucket
    aws_region      = var.aws_region
  }))

  # Tags
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "KedarWebAppInstance"
    }
  }

  # Optional dependency
  depends_on = [aws_db_instance.kedar_rds_instance]
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

# Create RDS instance (PostgreSQL example)
resource "aws_db_instance" "kedar_rds_instance" {
  identifier             = var.RDS_INSTANCE_IDENTIFIER # Unique identifier for the RDS instance
  engine                 = var.RDS_INSTANCE_ENGINE     # Database engine
  engine_version         = var.RDS_INSTANCE_ENGINE_VERSION
  instance_class         = var.RDS_INSTANCE_INSTANCE_CLASS            # Instance type (adjust based on needs)
  allocated_storage      = 20                                         # Amount of storage in GB
  username               = var.RDS_INSTANCE_USERNAME                  # Database username
  password               = var.RDS_INSTANCE_KEDAR_PASSWORD            # Password for the database
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name  # Subnet group for the RDS instance
  vpc_security_group_ids = [aws_security_group.rds_security_group.id] # Security group attached to the instance
  publicly_accessible    = false                                      # Set to true if you want the instance accessible from the internet
  skip_final_snapshot    = true                                       # Skip final snapshot on deletion
  db_name                = var.RDS_INSTANCE_DB_NAME

  # Use the correct attribute for parameter group
  parameter_group_name = aws_db_parameter_group.db_parameter_group.name

  tags = {
    Name = "KedarRDSInstance" # Tag for identification
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

# Listener for Load Balancer
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.app_load_balancer.arn
  port              = 80
  protocol          = "HTTP"

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

  min_size         = 3
  max_size         = 5
  desired_capacity = 3
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



