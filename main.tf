
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

#Explanation:
#VPC and Subnets: Creates a VPC with one public and one private subnet.
#Security Groups: Defines security groups for MongoDB and MongoExpress.
#EC2 Instance for MongoDB: Launches an EC2 instance in the public subnet with MongoDB running in a Docker container.
#ECS Cluster for MongoExpress: Sets up an ECS Fargate cluster and task definition for the MongoExpress web application.
#Load Balancer: Configures an ALB to route traffic to the MongoExpress service.
#S3 Backup and IAM Role: Creates an S3 bucket for MongoDB backups and an IAM role/policy to allow the EC2 instance to perform backups to S3.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.52.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.4.3"
    }
  }
  required_version = ">= 1.1.0"
}



provider "aws" {
  region = "eu-west-1"
  access_key = "AKIARATHADOVEYTEQYWI"
  secret_key = "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"
}

#This script accomplishes the following:

#Creates a VPC and a subnet.
#Creates security groups to allow SSH from the public internet and database traffic within the VPC.
#Creates an IAM role with ec2:* permissions and attaches it to the EC2 instance.
#Launches an EC2 instance with MongoDB installed and configured with authentication.
#Outputs the instance IP and MongoDB connection string.

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "main" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-1a"  # Choose an appropriate AZ
}

resource "aws_security_group" "allow_ssh" {
  name_prefix = "allow_ssh"
  description = "Allow SSH from the public internet"
  vpc_id      = aws_vpc.main.id

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
}

resource "aws_security_group" "allow_vpc" {
  name_prefix = "allow_vpc"
  description = "Allow all traffic within VPC"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "ec2_role" {
  name = "ec2_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "ec2_policy" {
  name = "ec2_policy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "ec2:*"
        Effect = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2_instance_profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_instance" "mongodb" {
  ami                    = "ami-08ba52a61087f1bd6"  # Choose an appropriate Amazon Linux 2 AMI
  instance_type         = "t2.micro"
  subnet_id             = aws_subnet.main.id
  security_groups       = [sg-0df153b608fa88559,sg-09bae9a43801a8cd7]
  iam_instance_profile  = aws_iam_instance_profile.ec2_instance_profile.name

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install -y mongodb4.0
              systemctl start mongod
              systemctl enable mongod

              # Setup MongoDB admin user
              mongo admin --eval 'db.createUser({user:"admin", pwd:"password", roles:[{role:"root", db:"admin"}]})'

              # Configure MongoDB authentication
              sed -i 's/#security:/security:\\n  authorization: "enabled"/' /etc/mongod.conf
              systemctl restart mongod
              EOF

  tags = {
    Name = "MongoDBServer"
  }
}

output "instance_ip" {
  value = aws_instance.mongodb.public_ip
}

output "connection_string" {
  value = "mongodb://admin:password@${aws_instance.mongodb.public_ip}:27017/admin"
}

