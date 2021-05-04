terraform {
    required_providers {
      aws = {
          source = "hashicorp/aws"
          version = "3.38.0"
      }
    }
}

#/*------------------AVAILABILITY ZONES--------------------------------*/
data "aws_availability_zones" "available" {
state = "available"
}
#/*------------------PROVIDER--------------------------------*/
provider "aws" {
    region = "ap-south-1"
}
#/*------------------VPC------------------------------------*/
resource "aws_vpc" "prod_vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_support   = true
    enable_dns_hostnames = true
tags = {
  Name = "prod_vpc"
}
}
#/*------------------SECURITY GROUPS------------------------------------*/
resource "aws_security_group" "sg_1" {
   name = "sg_1"
   vpc_id = aws_vpc.prod_vpc.id
  ingress {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
 egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "security_group"
  }
}
#/*------------------SUBNETS------------------------------------*/
resource "aws_subnet" "public_subnet" {
    vpc_id = aws_vpc.prod_vpc.id
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = true
    availability_zone = "ap-south-1a"
tags = {
  Name = "prod_public_subnet"
}
}
resource "aws_subnet" "private_subnet" {
    vpc_id = aws_vpc.prod_vpc.id
    cidr_block = "10.0.2.0/24"
    map_public_ip_on_launch  = true
    availability_zone = "ap-south-1b"
tags = {
  Name = "prod_private_subnet"
}
}
#/*------------------PUBLIC ROUTE_TABLE & INTERNET_GATEWAY------------------------------------*/
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.prod_vpc.id
tags = {
  Name = "public_rt"
}
}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.prod_vpc.id
tags = {
  Name = "public_igw"
}
}
resource "aws_route" "public_internet_gateway" {
    route_table_id = aws_route_table.public.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
}
#/*------------------ELASTICIP------------------------------------*/
resource "aws_eip" "nat_eip" {
    vpc = true
tags = {
  Name = "eip_nat"
}
}
#/*------------------PRIVATE ROUTE_TABLE & NAT_GATEWAY------------------------------------*/
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.prod_vpc.id

tags = {
  Name = "private_rt"
}
}
resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id = aws_subnet.private_subnet.id
tags = {
  Name = "private_ngw"
}
}
resource "aws_route" "public_nat_gateway" {
    route_table_id = aws_route_table.private.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.ngw.id
}
#/*------------------KET_PAIR------------------------------------*/
resource "aws_key_pair" "ec2key" {
  key_name = "ebs"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD3F6tyPEFEzV0LX3X8BsXdMsQz1x2cEikKDEY0aIj41qgxMCP/iteneqXSIFZBp5vizPvaoIR3Um9xK7PGoW8giupGn+EPuxIA4cDM4vzOqOkiMPhz5XK0whEjkVzTo4+S0puvDZuwIsdiW9mxhJc7tgBNL0cYlWSYVkz4G/fslNfRPW5mYAM49f4fhtxPb5ok4Q2Lg9dPKVHO/Bgeu5woMc7RY0p1ej6D4CKFE6lymSDJpW0YHX/wqE9+cfEauh7xZcG0q9t2ta6F6fmX0agvpFyZo8aFbXeUBr7osSCJNgvavWbM/06niWrOvYX2xwWdhXmXSrbX8ZbabVohBK41 email@example.com"
}
#/*------------------INSTANCES------------------------------------*/
resource "aws_instance" "public" {
    ami = "ami-010aff33ed5991201"
    instance_type = "t2.micro"
    subnet_id = aws_subnet.public_subnet.id
    vpc_security_group_ids = aws_security_group.sg_1.id
    key_name = aws_key_pair.ec2key.key_name
  tags = {
    Name = "public_subnet"
  }
}
resource "aws_instance" "private" {
    ami = "ami-010aff33ed5991201"
    instance_type = "t2.micro"
    subnet_id = aws_subnet.private_subnet.id
    vpc_security_group_ids = aws_security_group.sg_1.id
    key_name = aws_key_pair.ec2key.key_name
  tags = {
    Name = "private_subnet"
  }
}
