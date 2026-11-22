terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
provider "aws" {
  region = "us-east-1"
}
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "week1-public-subnet"
  }
}
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "week1-private-subnet"
  }
}
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "week1-internet-gateway"
  }
}
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "week1-public-route-table"
  }
}
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "week1-private-route-table"
  }
}
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}
resource "aws_security_group" "app" {
  name        = "week1-app-security-group"
  description = "Security group for the public application"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "week1-app-security-group"
  }
}
resource "aws_vpc_security_group_ingress_rule" "app_https" {
  security_group_id = aws_security_group.app.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"

  description = "Allow HTTPS from the internet"

  tags = {
    Name = "week1-app-https-ingress"
  }
}
resource "aws_vpc_security_group_egress_rule" "app_https" {
  security_group_id = aws_security_group.app.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"

  description = "Allow HTTPS to the internet"

  tags = {
    Name = "week1-app-https-egress"
  }
}
resource "aws_security_group" "database" {
  name        = "week1-database-security-group"
  description = "Security group for the private database"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "week1-database-security-group"
  }
}
resource "aws_vpc_security_group_ingress_rule" "database_from_app" {
  security_group_id = aws_security_group.database.id

  referenced_security_group_id = aws_security_group.app.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"

  description = "Allow PostgreSQL traffic from the application security group"

  tags = {
    Name = "week1-database-from-app-ingress"
  }
}
resource "aws_vpc_security_group_egress_rule" "app_to_database" {
  security_group_id = aws_security_group.app.id

  referenced_security_group_id = aws_security_group.database.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"

  description = "Allow PostgreSQL traffic to the database security group"

  tags = {
    Name = "week1-app-to-database-egress"
  }
}