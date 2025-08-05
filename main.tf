terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 6.0"   
    }
    tls = {
     source = "hashicorp/tls"
     version = "~> 4.0"   
    }
    local = {
      source = "hashicorp/local"
      version = "~> 2.0"
    }
  }        
}

provider "aws" {
  region = "us-east-1"
  
}

#Generate SSH Key Locally
resource "tls_private_key" "mcp_key" {
  algorithm = "RSA"
  rsa_bits = "4096"
}

#Register Public Key To AWS
resource "aws_key_pair" "mcp_key_pair" {
  key_name = "mcp-key"
  public_key = tls_private_key.mcp_key.public_key_openssh   
}

#Save The Private Key Locally
resource "local_file" "mcp_private_key" {
  content = tls_private_key.mcp_key.private_key_pem
  filename = "${path.module}/mcp-key.pem"
  file_permission = "0600"
}

#Get Default VPC
data "aws_vpc" "default" {
  default = true  
}

#Create Security Group
resource "aws_security_group" "mcp_sg" {
  name = "mcp-sg"
  description = "Allow HTTP and SSH traffic"
  vpc_id = data.aws_vpc.default.id

  ingress {
    description = "Allow HTTP"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["72.255.39.129/32"]
  }     

  egress {
    description = "Allow external traffic"
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Get Linux AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners = ["amazon"]
  
  filter {
    name = "name"
    values = ["amzn2-ami-hvm-*"]
  }
}

#Get Default Subnet
data "aws_subnets" "default" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.default.id] 
  }
}

#EC2 Instance Creation
resource "aws_instance" "mcp_instance" {
  ami = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  key_name = aws_key_pair.mcp_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.mcp_sg.id]
  subnet_id = data.aws_subnets.default.ids[0]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker
              sudo systemctl start docker
              sudo docker pull sohaibkhan007/developerfolio
              sudo docker run -d -p 80:3000 sohaibkhan007/developerfolio
              EOF
  tags = {
    Name = "mcp-emrn-ec2"
  }  
}

output "instance_public_ip" {
  value = aws_instance.mcp_instance.public_ip  
}