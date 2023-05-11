# AWS Blog application using DocumentDB

## What is being created
* VPC and VPC Endpoints
* DocumentDB (MongoDB compatible) cluster
* Backend Lambda Function
* Frontend Lambda Function

## How to setup
```bash
cd terraform/backend
pip install -r requirements.txt -t .

cd .. #into terraform directory

terraform init
terraform plan -out=plan.out
terraform apply plan.out
```