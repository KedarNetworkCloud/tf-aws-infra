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


# Create an EC2 Instance
resource "aws_instance" "kedar_web_app_instance" {
  ami                    = var.Kedar_AMI_ID              # Your custom AMI ID
  instance_type          = "t2.micro"                    # Adjust as necessary
  subnet_id              = aws_subnet.public_subnet_1.id # Use a subnet from your created VPC
  key_name               = "AWSDEMOROLESSH"
  vpc_security_group_ids = [aws_security_group.application_security_webapp_kedar.id] # Attach the security group

  associate_public_ip_address = true # Enable Public IP Assignment

  root_block_device {
    volume_size           = 25    # Root volume size
    volume_type           = "gp2" # General Purpose SSD
    delete_on_termination = true  # EBS volume should be deleted on instance termination
  }

  user_data = templatefile("./ec2InstanceUserData.sh", {
    DB_HOST         = aws_db_instance.kedar_rds_instance.endpoint                       # Full endpoint with port
    DB_HOST_NO_PORT = replace(aws_db_instance.kedar_rds_instance.endpoint, ":5432", "") # Remove the port directly
    DB_PASSWORD     = var.RDS_INSTANCE_KEDAR_PASSWORD
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

# Create RDS instance (PostgreSQL example)
resource "aws_db_instance" "kedar_rds_instance" {
  identifier             = "csye6225" # Unique identifier for the RDS instance
  engine                 = "postgres" # Database engine
  engine_version         = "15.8"
  instance_class         = "db.t3.micro"                              # Instance type (adjust based on needs)
  allocated_storage      = 20                                         # Amount of storage in GB
  username               = "csye6225"                                 # Database username
  password               = var.RDS_INSTANCE_KEDAR_PASSWORD            # Password for the database
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name  # Subnet group for the RDS instance
  vpc_security_group_ids = [aws_security_group.rds_security_group.id] # Security group attached to the instance
  publicly_accessible    = false                                      # Set to true if you want the instance accessible from the internet
  skip_final_snapshot    = true                                       # Skip final snapshot on deletion
  db_name                = "csye6225"

  # Use the correct attribute for parameter group
  parameter_group_name = aws_db_parameter_group.db_parameter_group.name

  tags = {
    Name = "KedarRDSInstance" # Tag for identification
  }
}


