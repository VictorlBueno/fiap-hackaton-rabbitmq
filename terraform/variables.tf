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
  description = "Ambiente (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "rabbitmq_instance_type" {
  description = "Tipo de instância EC2 para o RabbitMQ"
  type        = string
  default     = "t3.micro"
}

variable "rabbitmq_volume_size" {
  description = "Tamanho do volume EBS em GB"
  type        = number
  default     = 20
}

variable "rabbitmq_username" {
  description = "Usuário do RabbitMQ"
  type        = string
  default     = "admin"
}

 