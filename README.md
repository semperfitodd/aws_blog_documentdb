# AWS Blog application using a CRUD Lambda and DocumentDB
![architecture.png](images%2Farchitecture.png)
This is an application designed to demonstrate how to build a blog using AWS services including Lambda, DocumentDB, API Gateway, S3, CloudFront, and Route53. The backend of the application is built on a serverless architecture using AWS Lambda, which interacts with a DocumentDB cluster to perform CRUD (Create, Read, Update, Delete) operations. The frontend is hosted on S3 and delivered using CloudFront.

## Prerequisites

* AWS account with necessary permissions to create and manage the required resources
* AWS CLI installed and configured
* Terraform installed

## What is being created
* VPC and VPC Endpoints
* DocumentDB (MongoDB compatible) cluster
* AWS Secret with username and password for cluster
* Backend Lambda Function
* API Gateway
* Frontend in S3/CloudFront
* index.html as an object in S3
* ACM Certificate
* DNS in Route53

## Configuration
Before you run the Terraform commands, you need to update a few configuration values. Open the variables.tf file (assuming it exists) and set the following:

* environment: This value represents the environment in which you're deploying the application (for example, "dev", "staging", or "prod"). Replace it with the appropriate value for your situation.

* public_domain: This is the domain where your application will be hosted. Replace it with your domain.

## How to setup
It will take about 10 minutes for the terraform to run.

Please note: It takes a little extra time for the CDN to become ready after the terraform runs

Install python requirements 
```bash
cd terraform/backend
pip install -r requirements.txt -t .
```
![pip_install.png](images%2Fpip_install.png)
Initialize Terraform
```bash
cd .. #into terraform directory
terraform init
```
Run and save a plan
```bash
terraform plan -out=plan.out
```
![tf_plan.png](images%2Ftf_plan.png)
And then apply it
```bash
terraform apply plan.out
```
Read the outputs
![outputs.png](images%2Foutputs.png)
## Go to URL
https://blog.<YOUR_DOMAIN>

Please note: If you build your CloudFront distribution anywhere other than us-east-1, there is an issue with AWS DNS for S3 buckets that takes about 2 hours to propogate. You will get a 400 error until this resolves. Just give it some time.

To test when this starts working simply run this command in bash
```bash
while true; do
  if curl -Is https://blog.<YOUR_DOMAIN> | head -n 1 | grep -q "200"; then
    break
  fi
  sleep 5
done

```
Get will load all messages each time the page loads.

Test several 'Create' posts
![website.png](images%2Fwebsite.png)

## Troubleshooting
Make sure the backend is working for your CRUD application

Get Invoke URL from the outputs of the TF apply
### CREATE
```bash
curl -X POST -H "Content-Type: application/json" -d \
'{"httpMethod": "POST", "body": "{\"title\": \"Test Post\", \"content\": \"Cool stuff I am m doing.\"}"}' \
https://<API_GATEWAY_INVOKE_URL>/posts
```
### READ
```bash
curl -X GET https://<API_GATEWAY_INVOKE_URL>/posts/posts
```
### UPDATE
```bash
curl -X PUT -H "Content-Type: application/json" -d \
'{"content":"This is an updated test post."}' \
https://<API_GATEWAY_INVOKE_URL>/posts/posts/{id}
```
### DELETE
```bash
curl -X DELETE https://<API_GATEWAY_INVOKE_URL>/posts/posts/{id}
```
## Cleanup
Run a terraform destroy command
```bash
terraform destroy
```
![tf_destroy.png](images%2Ftf_destroy.png)