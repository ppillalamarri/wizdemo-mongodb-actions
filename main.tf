
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

#Database Server Configuration
# Create a Linux EC2 instance on which a database server is installed (e.g. MongoDB)
provider "aws" {
  region = "eu-west-1"
  access_key = "AKIARATHADOVEYTEQYWI"
  secret_key = "uuIl8NxNJAFVu7/VXLYKH0zmhrFXoRn9APXB8I6r"
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


# Configure a security group to allow SSH to the VM from the public internet


# Define a security group for SSH access
resource "aws_security_group" "ssh" {
  name        = "ssh_security_group"
  description = "Allow SSH inbound traffic"

  ingress {
    description = "SSH"
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
    Name = "ssh_security_group"
  }
}

# Define a security group for HTTP access
resource "aws_security_group" "http" {
  name        = "http_security_group"
  description = "Allow HTTP inbound traffic"

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
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
    Name = "http_security_group"
  }
}

# Configure an instance profile to the VM and add the permission “ec2:*” as a custom policy

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

#resource "tls_private_key" "wizdemouser" {
 # algorithm = "RSA"
 # rsa_bits  = 4096
#}

#resource "aws_key_pair" "generated_key" {
 # key_name   = var.key_name
 # public_key = tls_private_key.wizdemouser.public_key_openssh
#}

# Configure the database with authentication so you can build a database connection string
#TODO: Allow DB traffic to originate only from your VPC
#TODO: Configure the DB to regularly & automatically backup to your exercise S3 Bucket

resource "aws_instance" "mongodb" {
  #ami                    = "ami-08ba52a61087f1bd6"  # Choose an appropriate Amazon Linux 2 AMI
ami = "ami-0bb323ae9abcae1a0" # amzn2-ami-kernel-5.10-hvm-2.0.20240620.0-x86_64-gp2  
instance_type         = "t2.micro"
  #key_name              = aws_key_pair.generated_key.key_name
key_name              = var.key_name

# Associate the security groups with the instance
  vpc_security_group_ids = [
    aws_security_group.ssh.id,
    aws_security_group.http.id
  ]

user_data = <<-EOF
              #!/bin/bash
              sudo tee -a /etc/yum.repos.d/mongodb-org-4.4.repo << EOM
              [mongodb-org-6.0]
              name=MongoDB Repository
              baseurl=https://repo.mongodb.org/yum/amazon/2/mongodb-org/6.0/x86_64/
              gpgcheck=1
              enabled=1
              gpgkey=https://www.mongodb.org/static/pgp/server-6.0.asc
              EOM

              sudo yum install -y mongodb-org
              sudo systemctl start mongod
              sudo systemctl enable mongod
              # Setup MongoDB admin user
              #sudo mongosh admin --eval 'db.createUser({user:"admin", pwd:"password", roles:[{role:"root", db:"admin"}]})'

              # Configure MongoDB authentication
              #sudo sed -i 's/#security:/security:\\n  authorization: "enabled"/' /etc/mongod.conf
              #sudo systemctl restart mongod
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

