# cointracker_hello_world 0.1.0

This is a simple Flask API that returns "Hello World!" to all incoming requests. The application is Dockerized and hosted with web server Gunicorn. The image is pushed to AWS' ECR and is hosted on ECS and managed by Fargate with an ALB in front. This project uses Python's Poetry dependency manager with pyproject.toml instead of pip. All infrastructure mentioned is defined in Terraform. The state file is hosted remotely on S3 and there is a DynamoDB table to handle locks to prevent multiple developers trying to make changes to the same resources at the same time.

Github Actions is used as a CI/CD tool to automatically build and push the Docker image to ECR as shown in the deploy.yml. Also in the deploy.yml file is instructions to run Terraform plan and apply upon merges or pushes to main branch.

## Requirements/Libraries:

- Python 3.10+
- Poetry
- AWS CLI installed and AWS account configured to user with permissions to create and destroy resources.
- Terraform
- Flask
