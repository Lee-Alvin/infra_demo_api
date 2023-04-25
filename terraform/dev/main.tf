#Hosting the state file remotely to disallow multiple devs making changes to the same resources at once
resource "aws_s3_bucket" "terraform_state_file" {
  bucket        = "terraform-state-file-cointracker-hello-world"
  force_destroy = true
  tags          = var.tags
}

resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
  bucket = aws_s3_bucket.terraform_state_file.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_encryption" {
  bucket = aws_s3_bucket.terraform_state_file.bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_dynamodb_table" "terraform_state_lock" {
  name         = "terraform_state_lock_cointracker_hello_world"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

#Create the ECR where we will push the Dockerfiles
resource "aws_ecr_repository" "cointracker_hello_world_ecr" {
  name                 = "cointracker_hello_world_ecr"
  image_tag_mutability = "MUTABLE"

  tags = var.tags
}

#Creating the task definition and roles that will be used by Fargate
data "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"
}

resource "aws_ecs_task_definition" "cointracker_hello_world_task_definition" {
  family                   = "cointracker_hello_world_task_definition"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory
  execution_role_arn       = data.aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([
    {
      "name" : "cointracker_hello_world_container",
      "image" : "${var.docker_repo}",
      "essential" : true,
      "memoryReservation" : 512,
      "portMappings" : [
        {
          "containerPort" : 8080,
          "hostPort" : 8080
        }
      ]
    }
  ])
}


#routing, availability zones, public subnets
data "aws_availability_zones" "azs" {}

resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "cointracker_hello_world_igw"
  }
}

resource "aws_route_table" "rt_public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name = "cointracker_hello_world_rt_public"
  }
}

resource "aws_subnet" "public_subnets" {
  count             = var.subnet_count
  cidr_block        = "10.0.${var.subnet_count + count.index + 1}.0/24"
  availability_zone = data.aws_availability_zones.azs.names[count.index]
  vpc_id            = aws_vpc.vpc.id

  tags = {
    Name = "cointracker_hello_world_public_${count.index + 1}"
  }
}

resource "aws_route_table_association" "public_rt_association" {
  count          = var.subnet_count
  route_table_id = aws_route_table.rt_public.id
  subnet_id      = aws_subnet.public_subnets.*.id[count.index]
}

#security groups controlling access to the ALB and to the ECS cluster
resource "aws_security_group" "alb_sg" {
  name   = "cointracker_hello_world_alb_sg"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = [
    "0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
    "0.0.0.0/0"]
  }
}

resource "aws_security_group" "ecs_sg" {
  name   = "ecs-from-alb-group"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Application load balancer that will be directing external traffic to containers in ECS cluster
resource "aws_alb" "cointracker_hello_world_alb" {
  load_balancer_type = "application"
  name               = "cointracker-hello-world-alb"
  subnets            = aws_subnet.public_subnets.*.id
  security_groups    = [aws_security_group.alb_sg.id]
}

# point redirected traffic to the app
resource "aws_alb_target_group" "target_group" {
  name        = "cointracker-hello-world-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc.id
  target_type = "ip"
}

# direct traffic through the ALB
resource "aws_alb_listener" "cointracker_alb_listener" {
  load_balancer_arn = aws_alb.cointracker_hello_world_alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    target_group_arn = aws_alb_target_group.target_group.arn
    type             = "forward"
  }
}

#Putting it all together with ECS cluster and the actual cointracker_hello_world service
resource "aws_ecs_cluster" "cointracker_hello_world" {
  name = "cointracker_hello_world"

  tags = {
    Name = "cointracker_hello_world"
  }
}

resource "aws_ecs_service" "cointracker_hello_world_service" {
  name            = "cointracker_hello_world_service"
  task_definition = aws_ecs_task_definition.cointracker_hello_world_task_definition.arn
  desired_count   = 2
  cluster         = aws_ecs_cluster.cointracker_hello_world.id
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_sg.id]
    subnets          = aws_subnet.public_subnets.*.id
    assign_public_ip = true
  }

  load_balancer {
    container_name   = "cointracker_hello_world_container"
    container_port   = "8080"
    target_group_arn = aws_alb_target_group.target_group.id
  }

  depends_on = [
    aws_alb_listener.cointracker_alb_listener
  ]
}
