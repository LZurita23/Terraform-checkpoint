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

resource "aws_egress_only_internet_gateway" "egw" {
  vpc_id = aws_vpc.vpc1.id

  tags = {
    Name = "checkpoint-egw"
  }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpc1.id

  route {
    cidr_block = "10.0.30.0/24"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    egress_only_gateway_id = aws_egress_only_internet_gateway.egw.id
  }

  tags = {
    Name = "checkpoint-rt"
  }
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
    cidr_blocks      = [aws_vpc.vpc1.cidr_block]
    ipv6_cidr_blocks = [aws_vpc.vpc1.ipv6_cidr_block]
  }

  ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.vpc1.cidr_block]
    ipv6_cidr_blocks = [aws_vpc.vpc1.ipv6_cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
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
  availability_zone = "us-east-1"
  security_groups = ["${aws_security_group.checkpoint-sg.name}"]
  subnet_id = var.common_cidr_block
  user_data = file("install.sh")

  tags = {
    Name = "checkpoint-ec2"
  }
}
