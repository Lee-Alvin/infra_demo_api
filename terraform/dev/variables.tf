variable "env" {
  type    = string
  default = "dev"
}

variable "subnet_count" {
  default = 2
}

variable "fargate_cpu" {
  default = 256
}

variable "fargate_memory" {
  default = 1024
}

variable "service_name" {
  default = "cointracker_hello_world_ecr"
}

variable "region" {
  default = "us-east-1"
}

variable "account_id" {
  default = "523878000693"
}

variable "docker_repo" {
  default = "${account_id}.dkr.ecr.${service_name}.amazonaws.com/${service_name}:latest"
}

variable "tags" {
  type = map(string)
  default = {
    environment  = "development"
    service_name = "cointracker_hello_world"
  }
}
