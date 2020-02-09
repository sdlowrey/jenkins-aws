locals {
  # TODO some of these should be inputs
  key_name = "ws-devops"
  department = "devops"
  region = "us-east-2"
}

output "master_public_ip" {
  value = aws_instance.jenkins-master.public_ip
}

terraform {
  backend "s3" {
    bucket = "w.devops"
    key = "tfstate/jenkins/"
    region = "us-east-2"
  }
}

provider "aws" {
  version = "~> 2.48"
  region = local.region
}

data "aws_ami" "amazon-linux-2" {
  most_recent = true
  filter {
    name = "name"
    values = ["amzn2-ami-hvm-2.0.20191024.3-x86_64-ebs"]
  }
  owners = ["137112412989"] # Amazon
}

resource "aws_vpc" "jenkins" {
  cidr_block = "10.8.0.0/16"
  tags = {
    Name = "jenkins"
    department = local.department
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.jenkins.id
  tags = {
    Name = "jenkins-main"
    department = local.department
  }
}

resource "aws_subnet" "jenkins-public" {
  vpc_id = aws_vpc.jenkins.id
  cidr_block = "10.8.1.0/24"
  tags = {
    Name = "jenkins-public"
    department = local.department
  }
}

resource "aws_route_table" "jenkins-public" {
  vpc_id = aws_vpc.jenkins.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "jenkins-public"
    department = local.department
  }
}

resource aws_route_table_association "jenkins-public" {
  route_table_id = aws_route_table.jenkins-public.id
  subnet_id = aws_subnet.jenkins-public.id
}

resource "aws_security_group" "allow_ssh_http" {
  vpc_id = aws_vpc.jenkins.id
  name = "allow_ssh_http"
  description = "Allow SSH and HTTP from devops"

  ingress {
    from_port = 80
    protocol = "tcp"
    to_port = 80
    cidr_blocks = ["71.255.255.76/32"]
  }

  ingress {
    from_port = 22
    protocol = "tcp"
    to_port = 22
    cidr_blocks = ["71.255.255.76/32"]
  }

  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh_http"
    department = local.department
  }
}

resource "aws_instance" "jenkins-master" {
  ami = data.aws_ami.amazon-linux-2.id
  instance_type = "t3.medium"
  key_name = local.key_name
  subnet_id = aws_subnet.jenkins-public.id
  vpc_security_group_ids = [aws_security_group.allow_ssh_http.id]
  associate_public_ip_address = true

  tags = {
    Name = "jenkins-master"
    department = local.department
  }
}