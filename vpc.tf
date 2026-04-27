# VPC
resource "aws_vpc" "securescale" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "SecureScale-VPC"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "securescale" {
  vpc_id = aws_vpc.securescale.id

  tags = {
    Name = "SecureScale-IGW"
  }
}

# Public Subnet 1 - us-east-1a
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.securescale.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "SecureScale-Public-1"
  }
}

# Public Subnet 2 - us-east-1b
resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.securescale.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "SecureScale-Public-2"
  }
}

# Private Subnet 1 - us-east-1a
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.securescale.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "SecureScale-Private-1"
  }
}

# Private Subnet 2 - us-east-1b
resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.securescale.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "SecureScale-Private-2"
  }
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.securescale.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.securescale.id
  }

  tags = {
    Name = "SecureScale-Public-RT"
  }
}

# Associate Public Subnets to Route Table
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}