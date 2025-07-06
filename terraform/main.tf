data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "fiap-hack-terraform-state"
    key    = "vpc/terraform.tfstate"
    region = "us-east-1"
  }
}

locals {
  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Component   = "rabbitmq"
  }
}

resource "aws_security_group" "rabbitmq" {
  name_prefix = "fiap-hack-rabbitmq-"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id
  
  ingress {
    from_port       = 5672
    to_port         = 5672
    protocol        = "tcp"
    security_groups = [data.terraform_remote_state.vpc.outputs.cluster_security_group_id]
    description     = "AMQP"
  }
  
  ingress {
    from_port       = 15672
    to_port         = 15672
    protocol        = "tcp"
    security_groups = [data.terraform_remote_state.vpc.outputs.cluster_security_group_id]
    description     = "Management UI"
  }
  
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [data.terraform_remote_state.vpc.outputs.cluster_security_group_id]
    description     = "SSH"
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(local.tags, {
    Name = "fiap-hack-rabbitmq-sg"
  })
}

resource "aws_instance" "rabbitmq" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.rabbitmq_instance_type
  vpc_security_group_ids = [aws_security_group.rabbitmq.id]
  subnet_id              = data.terraform_remote_state.vpc.outputs.private_subnet_ids[0]
  
  root_block_device {
    volume_size = var.rabbitmq_volume_size
    volume_type = "gp2"
    
    tags = merge(local.tags, {
      Name = "fiap-hack-rabbitmq-root-volume"
    })
  }
  
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    rabbitmq_username = var.rabbitmq_username
    rabbitmq_password = random_password.rabbitmq_password.result
  }))
  
  tags = merge(local.tags, {
    Name = "fiap-hack-rabbitmq"
  })
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "random_password" "rabbitmq_password" {
  length  = 16
  special = false
  upper   = true
  lower   = true
  numeric = true
}

resource "aws_secretsmanager_secret" "rabbitmq_credentials" {
  name = "${var.project_name}/rabbitmq-credentials"
  
  tags = local.tags
}

resource "aws_secretsmanager_secret_version" "rabbitmq_credentials" {
  secret_id = aws_secretsmanager_secret.rabbitmq_credentials.id
  secret_string = jsonencode({
    username = var.rabbitmq_username
    password = random_password.rabbitmq_password.result
    host     = aws_instance.rabbitmq.private_ip
    port     = 5672
    management_port = 15672
    management_url  = "http://${aws_instance.rabbitmq.private_ip}:15672"
    amqp_url        = "amqp://${var.rabbitmq_username}:${random_password.rabbitmq_password.result}@${aws_instance.rabbitmq.private_ip}:5672/"
  })
}

output "rabbitmq_private_ip" {
  description = "IP privado da instância RabbitMQ"
  value       = aws_instance.rabbitmq.private_ip
}

output "rabbitmq_instance_id" {
  description = "ID da instância RabbitMQ"
  value       = aws_instance.rabbitmq.id
}

output "rabbitmq_secret_arn" {
  description = "ARN do secret com as credenciais do RabbitMQ"
  value       = aws_secretsmanager_secret.rabbitmq_credentials.arn
}

output "rabbitmq_security_group_id" {
  description = "ID do security group do RabbitMQ"
  value       = aws_security_group.rabbitmq.id
}

output "rabbitmq_management_url" {
  description = "URL da interface de gerenciamento do RabbitMQ"
  value       = "http://${aws_instance.rabbitmq.private_ip}:15672"
}

output "rabbitmq_amqp_url" {
  description = "URL AMQP do RabbitMQ"
  value       = "amqp://${var.rabbitmq_username}:${random_password.rabbitmq_password.result}@${aws_instance.rabbitmq.private_ip}:5672/"
  sensitive   = true
} 