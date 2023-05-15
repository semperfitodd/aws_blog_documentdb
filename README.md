# AWS Blog application using a CRUD Lambda and DocumentDB

## What is being created
* VPC and VPC Endpoints
* DocumentDB (MongoDB compatible) cluster
* Backend Lambda Function
* API Gateway
* Frontend in S3/CloudFront
* index.html as an object in S3
* DNS in Route53

## How to setup
Update locals.tf with desired declarations

It will take about 10 minutes for the terraform to run.

Please note: It takes a little extra time for the CDN to become ready after the terraform runs
```bash
cd terraform/backend
pip install -r requirements.txt -t .

cd .. #into terraform directory

terraform init
terraform plan -out=plan.out
terraform apply plan.out
```

## Go to URL
https://blog.<YOUR_DOMAIN>

Please note: If you build your CloudFront distribution anywhere other than us-east-1, there is an issue with AWS DNS for S3 buckets that takes about 2 hours to propogate. You will get a 400 error until this resolves. Just give it some time.

To test when this starts working simply run this command in bash
```bash
while ! curl -Is https://blog.<YOUR_DOMAIN> | head -n 1 | grep -q "200"; do sleep 5; done
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