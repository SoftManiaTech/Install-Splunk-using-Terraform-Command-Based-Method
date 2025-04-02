terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.region
}

data "aws_ami" "latest_rhel" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["RHEL-9.0*"]  # Fetches latest RHEL AMI
  }
}

resource "aws_security_group" "splunk_sg" {
  name        = "splunk-security-group"
  description = "Allow Splunk ports"

   ingress { 
    from_port = 22
    to_port = 22 
    protocol = "tcp" 
    cidr_blocks = ["0.0.0.0/0"] 
    }

  ingress {
    from_port   = 8000
    to_port     = 9999
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Open to all (Restrict for security)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "splunk_server" {
  ami           = data.aws_ami.latest_rhel.id
  instance_type = "t2.medium"
  key_name      = var.key_name  # Change to your key name
  security_groups = [aws_security_group.splunk_sg.name]

  user_data = file("splunk-setup.sh")

  tags = {
    Name = "Splunk-Server"
  }
}

output "public_ip" {
  value = aws_instance.splunk_server.public_ip
}
