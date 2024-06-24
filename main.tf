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
  region = "eu-west-2",
  access_key = "AKIARATHADOVORWQJWVE"
  secret_key = "-----BEGIN RSA PRIVATE KEY-----MIIEowIBAAKCAQEApAJJ3GJp\/TgWpbrDUTFO9e+AfWnjCeqng1rDgo6dOCacNGrA7hi4leHqj56yPeAhnSwlQpe\/ODnAfLnkTV4Z+Yd3ba787sM37V+qYxB3AAScoGJKokfQlOcyNhwNvB9FL7N7eGoI6e5HIjWERGIbfCZLrT8Mkkz5PkbQjmFrB3vQEMcuGIvnBdLg7LuoMeqsnRoUTUAqViOnPcYZmSn4vOpjkn4nM58Its96noIoWz+yJqy4LTa2cLUHNl49yaKxjb7P2jcJxJCuMytZUFCJmHiXcbuC2rUfEBPDJQMW2fwBDALtjlPg\/SpX4Xnwu0lUMV7tWSbv+uCDlQDdXYuPJQIDAQABAoIBAHJlZj9iJauJw8I1Uqb\/TaQdOfJAOSxhkBX+6P\/XmbHgvHOTQp7Qf2+L9J\/YgVrHSqrmb9bTIX2GSsy0nJmaWWPDKXpH5ARmBkx7vcz7XwWUMetso8ItdT9nQ46aYrok1Y1AE48Z5r3EhblGuss34xPlYkOlBo\/FQNQ\/cJjfOlgs1MZ0AN1rYky0jcAj\/7E9DwF3QmnPbFJVxqrPKcF5GCLNI89Mr3LbZlQg74Axm63TxTPW1s9RuZSA\/BDHuWOKNH\/0Hvd68isNC4rGyePOygIwYAppvoMvLlseZfir3qmUF9KO08D53Byjps6W7HBHSjRgZ5Ia+QyDCXLQMUeKdsECgYEA4yLoqbMHG5vrCupZwv5iFQ6KbDiuayLJqgnh\/pVpHcbEfzD59T2NIp5ht0pGrff39CJy5SeEaD4nXjkj7+kjqiHvplspWthW222wbpn\/IKb8tjI1XaT2ZJ8EzpiJI64\/okopL2cbpKZuhGya3IaGD5kfnDhZsI7YOEl8gzzEBYsCgYEAuNm\/pvnVzHGSviXyEeJ1ryGRKHpCl373SLxqZabRSeozeZeifQ1lW9aeTu0uVE8fUExKQHwEJ3QVrTDRltdtECU+AkYwTmKZCTUGULZb5+hJPajYFV39iEuIRgyZt+lpvzlYf25hBaTH0E7NXXZVFdhvMDqu5iJPUS0WS3qtNA8CgYA5i7Keq\/j1Cb+2+EDdok1\/QDvZx1KJWjr1laNoOLp1DNLj1qi9dWa4ip\/\/LBZUJSrw83lgjW6CapzWxmtQcSTUCd0JrLcBiSYYWeYFX4a\/4w7LqlTS8ORsAc3Z+dNk8tS0bU2Z8OmUAYamjk196ac1dHoJvk0a6lXljNi69z5CmQKBgD5KusgFJyQnHcFQPjwCqY\/j6uvOD4TH94MeY2hwB9U1xDT0gYBMtFx3fY+xY8xrgWzo2JjUcf3to6RicC651\/n54uSXTI4Nse6lXMR0P5Jt98h8jpzcuKRmd7zLYD3WvZkANS90PePN\/LvY4mHdj5y1+\/ovvGK3Ky162SmEZLvHAoGBAKwmlOERiPKszNlLYF5ihimJZ57HJMXD78rFab2uqJ4\/K\/BJOhkZSJUH++s+Or5OOw\/pKaM+Mgd40SaQ1wWQQoRtDPkBwT3DFLRsOGgmTRu5G5UdPdZzDfeEOmwi1\/jmYykGAAlqWf5orI0XYqnTaQoFWdKsNUGZWNlGQo2BMr\/E-----END RSA PRIVATE KEY-----"
}
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

resource "aws_instance" "web" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.web-sg.id]

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y apache2
              sed -i -e 's/80/8080/' /etc/apache2/ports.conf
              echo "Hello World" > /var/www/html/index.html
              systemctl restart apache2
              EOF
}

resource "aws_security_group" "web-sg" {
  name = "${random_pet.sg.id}-sg"
  ingress {
    from_port   = 8080
    to_port     = 8080
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

output "web-address" {
  value = "${aws_instance.web.public_dns}:8080"
}
