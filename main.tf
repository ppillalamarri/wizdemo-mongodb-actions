
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
}
