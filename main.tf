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

// Application Security Group
resource "aws_security_group" "application_security_webapp_kedar" {
  name        = "application_security_group"
  description = "Security group for web application instances"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 22 # Allow SSH
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80 # Allow HTTP
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443 # Allow HTTPS
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080 # Replace with your application's port
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound rules to allow all traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # "-1" allows all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "application security group"
  }
}


resource "aws_s3_bucket" "demo_s3_bucket" {
  bucket = "demo-s3-bucket-${uuid()}"  # Use UUID function for uniqueness

  tags = {
    Name = "DemoS3Bucket"
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
          "s3:DeleteObject",     # Allows deletion of objects
          "s3:DeleteBucket"      # Allows deletion of the bucket itself
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

resource "aws_instance" "kedar_web_app_instance" {
  ami                    = var.Kedar_AMI_ID
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet_1.id
  key_name               = "AWSDEMOROLESSH"
  vpc_security_group_ids = [aws_security_group.application_security_webapp_kedar.id]

  associate_public_ip_address = true

  iam_instance_profile = aws_iam_instance_profile.ec2_s3_instance_profile.name  # Attach the IAM role

  root_block_device {
    volume_size           = 25
    volume_type           = "gp2"
    delete_on_termination = true
  }

  user_data = templatefile("./ec2InstanceUserData.sh", {
    DB_HOST         = aws_db_instance.kedar_rds_instance.endpoint
    DB_HOST_NO_PORT = replace(aws_db_instance.kedar_rds_instance.endpoint, ":5432", "")
    DB_PASSWORD     = var.RDS_INSTANCE_KEDAR_PASSWORD
    DB_NAME         = var.RDS_INSTANCE_DB_NAME
    DB_USERNAME     = var.RDS_INSTANCE_USERNAME
    S3_BUCKET_NAME  = aws_s3_bucket.demo_s3_bucket.bucket
    aws_region = var.aws_region
  })

  depends_on = [aws_db_instance.kedar_rds_instance]

  tags = {
    Name = "KedarWebAppInstance"
  }
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

resource "aws_route53_record" "demo_a_record" {
  zone_id = data.aws_route53_zone.demo.zone_id
  name     = "${var.DEMO_SUBDOMAIN_NAME}.${var.MAIN_DOMAIN_NAME}"
  type     = "A"
  ttl      = 60
  records  = [aws_instance.kedar_web_app_instance.public_ip]
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


