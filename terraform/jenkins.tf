provider "aws" {
  version = "~> 2.48"
  region = "us-east-2"
}

resource "aws_vpc" "jenkins" {
  cidr_block = "10.8.0.0/16"
}