# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

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
  region = "eu-north-1"
}

resource "random_pet" "sg" {}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}


resource "aws_security_group" "web-sg" {
  name = "${random_pet.sg.id}-sg"
  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  // connectivity to ubuntu mirrors is required to run `apt-get update` and `apt-get install apache2`
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Provider configuration
provider "kubernetes" {
  config_path = "~/.kube/config"  # Path to your kubeconfig file
}
# Create a Kubernetes deployment
resource "kubernetes_deployment" "example_deployment" {
  metadata {
    name = "example-deployment"
    labels = {
      app = "example-app"
    }
  }
  spec {
    replicas = 3
    selector {
      match_labels = {
        app = "example-app"
      }
    }
    template {
      metadata {
        labels = {
          app = "example-app"
        }
      }
      spec {
        container {
          name = "example-container"
          image = "mongo:latest"
          # Other container configurations as needed
         }
         container {
          name = "example-container"
          image = "mongo-express"
          # Other container configurations as needed
        }
      }
    }
  }
}
# Create a Kubernetes service
resource "kubernetes_service" "example_service" {
  metadata {
    name = "example-service"
  }
  spec {
    selector = {
      app = "example-app"
    }
    port {
      port        = 8081
      target_port = 8081
    }
  }
}



output "web-address" {
  value = "${aws_instance.web.public_dns}:8081"
}
