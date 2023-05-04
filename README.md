# infra_demo_api 0.1.0

This is a simple Flask API that returns "Hello World!" to all incoming requests. The application is Dockerized and hosted with web server Gunicorn. The image is pushed to AWS' ECR and is hosted on ECS and managed by Fargate with an ALB in front. This project uses Python's Poetry dependency manager with pyproject.toml instead of pip. All infrastructure mentioned is defined in Terraform. The state file is hosted remotely on S3 and there is a DynamoDB table to handle locks to prevent multiple developers trying to make changes to the same resources at the same time.

Github Actions is used as a CI/CD tool to automatically build and push the Docker image to ECR as shown in the deploy.yml. Also in the deploy.yml file is instructions to run Terraform plan and apply upon merges or pushes to main branch.

To run locally, use docker-compose to build and start a nginx and gunicorn web server to host the Flask API.

## Requirements/Libraries:

- Python 3.10+
- Poetry
- Docker
- AWS CLI installed and AWS account configured to user with permissions to create and destroy resources.
- Terraform
- Flask
- Postman

## Running and Testing Locally:

To run and the application locally, you will need Docker installed. Navigate to the root and run below to build the image and run:

```
    docker-compose build
    docker-compose up
```

Then, open Postman and you can send test requests to http://127.0.0.1:80 . Behind the scenes, a container for a nginx web server and a container for a Gunicorn web server hosting the Flask API are started up.
