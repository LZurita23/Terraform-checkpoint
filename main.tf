terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Create a VPC
resource "aws_vpc" "vpc1" {
  cidr_block = "10.0.0.0/16"

  tags = {
      Name = "checkpoint-vpc"
  }
}

#Create a variable
variable "common_cidr_block" {
  type = string
  default = "10.0.30.0/24"
}

# Create a subnet
resource "aws_subnet" "subnet0" {
  vpc_id     = aws_vpc.vpc1.id 
  cidr_block = var.common_cidr_block
  map_public_ip_on_launch = true

  tags = {
    Name = "checkpoint-subnet"
  }
}

output "subnet0_id" {
  value = aws_subnet.subnet0.vpc_id
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc1.id

  tags = {
    Name = "checkpoint-gw"
  }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpc1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "checkpoint-rt"
  }
}

resource "aws_route_table_association" "rta" {
  subnet_id      = aws_subnet.subnet0.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_security_group" "checkpoint-sg" {
  name        = "checkpoint-sg"
  description = "Allow SSH & HTTP inbound traffic"
  vpc_id      = aws_vpc.vpc1.id

  ingress {
    description      = "SSH from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]

  }

  ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]

  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "checkpoint-sg"
  }
}

resource "aws_instance" "ec2" {
  ami = "ami-04ad2567c9e3d7893"
  instance_type = "t2.micro"
  key_name = "SDIT4"
  associate_public_ip_address = true
  security_groups = [aws_security_group.checkpoint-sg.id]
  subnet_id = aws_subnet.subnet0.id
  user_data = file("install.sh")

  tags = {
    Name = "checkpoint-ec2"
  }
}
