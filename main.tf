provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}


resource "aws_vpc" "main_vpc" {
  cidr_block       = var.vpc_cidr

  tags = {
    Name = "KedarMainVPC"  // This uses the VPC name from our .tfvars file. This is the name that would show up in the AWS console.
  }
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.public_subnet_cidr_1
  availability_zone       = var.subnet_1_zone

  tags = {
    Name = "Public Subnet 1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.public_subnet_cidr_2
  availability_zone       = var.subnet_2_zone

  tags = {
    Name = "Public Subnet 2"
  }
}

resource "aws_subnet" "public_subnet_3" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.public_subnet_cidr_3
  availability_zone       = var.subnet_3_zone

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
    from_port   = 22      # Allow SSH
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80      # Allow HTTP
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
  from_port   = 443     # Allow HTTPS
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080     # Replace with your application's port
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "application security group"
  }
}

# Create an EC2 Instance
resource "aws_instance" "kedar_web_app_instance" {
  ami                    = var.Kedar_AMI_ID.id  # Your custom AMI ID
  instance_type         = "t2.micro"       # Adjust as necessary
  subnet_id             = aws_subnet.public_subnet_1.id  # Use a subnet from your created VPC
  key_name              = "AWSDEMOROLESSH" 
  vpc_security_group_ids = [aws_security_group.application_security_webapp_kedar.id]  # Attach the security group

  associate_public_ip_address = true  # Enable Public IP Assignment

  root_block_device {
    volume_size = 25  # Root volume size
    volume_type = "gp2"  # General Purpose SSD
    delete_on_termination = true  # EBS volume should be deleted on instance termination
  }

  tags = {
    Name = "KedarWebAppInstance"
  }
}
