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

variable "docker_repo" {
  default = "523878000693.dkr.ecr.us-east-1.amazonaws.com/cointracker_hello_world_ecr:latest"
}

variable "tags" {
  type = map(string)
  default = {
    environment  = "development"
    service_name = "cointracker_hello_world"
  }
}
