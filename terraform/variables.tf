variable "aws_region" {
  description = "Região AWS onde os recursos serão criados"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nome do projeto"
  type        = string
  default     = "fiap-hack"
}

variable "environment" {
  description = "Ambiente (dev, staging, production)"
  type        = string
  default     = "production"
}

variable "rabbitmq_username" {
  description = "Usuário do RabbitMQ"
  type        = string
  default     = "admin"
}

variable "rabbitmq_replicas" {
  description = "Número de réplicas do RabbitMQ"
  type        = number
  default     = 1
}

 