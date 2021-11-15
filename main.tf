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




