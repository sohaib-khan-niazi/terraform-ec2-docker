# Terraform EC2 + Docker App Deployment

This project uses Terraform to deploy an EC2 instance on AWS, pull a Docker image, and run it automatically via `user_data`.

## 🔧 Features

- Launches a `t3.micro` EC2 in default VPC
- Generates and stores key pair locally
- Security group for port 80 (HTTP) access
- Uses `user_data` to install Docker and run a container
- Automatically deploys `sohaibkhan007/developerfolio`

## 🚀 Getting Started

```bash
terraform init
terraform plan
terraform apply

