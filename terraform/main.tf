data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "fiap-hack-terraform-state"
    key    = "vpc/terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket = "fiap-hack-terraform-state"
    key    = "eks/terraform.tfstate"
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

resource "random_password" "rabbitmq_password" {
  length  = 16
  special = false
  upper   = true
  lower   = true
  numeric = true
}

resource "kubernetes_namespace" "rabbitmq" {
  metadata {
    name = "rabbitmq"
    labels = local.tags
  }
}

resource "kubernetes_config_map" "rabbitmq_config" {
  metadata {
    name      = "rabbitmq-config"
    namespace = kubernetes_namespace.rabbitmq.metadata[0].name
  }

  data = {
    "rabbitmq.conf" = <<-EOF
      default_user = ${var.rabbitmq_username}
      default_pass = ${random_password.rabbitmq_password.result}
      default_vhost = /
    EOF
  }
}

resource "kubernetes_secret" "rabbitmq_credentials" {
  metadata {
    name      = "rabbitmq-credentials"
    namespace = kubernetes_namespace.rabbitmq.metadata[0].name
  }

  data = {
    username = var.rabbitmq_username
    password = random_password.rabbitmq_password.result
  }

  type = "Opaque"
}

resource "kubernetes_deployment" "rabbitmq" {
  metadata {
    name      = "rabbitmq"
    namespace = kubernetes_namespace.rabbitmq.metadata[0].name
    labels    = local.tags
  }

  spec {
    replicas = var.rabbitmq_replicas

    selector {
      match_labels = {
        app = "rabbitmq"
      }
    }

    template {
      metadata {
        labels = {
          app = "rabbitmq"
        }
      }

      spec {
        container {
          image = "rabbitmq:3.12-management"
          name  = "rabbitmq"

          port {
            container_port = 5672
            name          = "amqp"
          }

          port {
            container_port = 15672
            name          = "management"
          }

          env {
            name  = "RABBITMQ_DEFAULT_USER"
            value = var.rabbitmq_username
          }

          env {
            name  = "RABBITMQ_DEFAULT_PASS"
            value = random_password.rabbitmq_password.result
          }

          volume_mount {
            name       = "rabbitmq-config"
            mount_path = "/etc/rabbitmq"
          }

          volume_mount {
            name       = "rabbitmq-data"
            mount_path = "/var/lib/rabbitmq"
          }

          resources {
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "256Mi"
            }
          }
        }

        volume {
          name = "rabbitmq-config"
          config_map {
            name = kubernetes_config_map.rabbitmq_config.metadata[0].name
          }
        }

        volume {
          name = "rabbitmq-data"
          empty_dir {}
        }
      }
    }
  }
}

resource "kubernetes_service" "rabbitmq" {
  metadata {
    name      = "rabbitmq"
    namespace = kubernetes_namespace.rabbitmq.metadata[0].name
    labels    = local.tags
  }

  spec {
    selector = {
      app = "rabbitmq"
    }

    port {
      port        = 5672
      target_port = 5672
      name        = "amqp"
    }

    port {
      port        = 15672
      target_port = 15672
      name        = "management"
    }

    type = "ClusterIP"
  }
}

output "rabbitmq_namespace" {
  description = "Namespace do RabbitMQ"
  value       = kubernetes_namespace.rabbitmq.metadata[0].name
}

output "rabbitmq_service_name" {
  description = "Nome do service do RabbitMQ"
  value       = kubernetes_service.rabbitmq.metadata[0].name
}

output "rabbitmq_service_cluster_ip" {
  description = "IP do cluster do service RabbitMQ"
  value       = kubernetes_service.rabbitmq.spec[0].cluster_ip
}

output "rabbitmq_amqp_port" {
  description = "Porta AMQP do RabbitMQ"
  value       = 5672
}

output "rabbitmq_management_port" {
  description = "Porta de gerenciamento do RabbitMQ"
  value       = 15672
}

output "rabbitmq_username" {
  description = "Usuário do RabbitMQ"
  value       = var.rabbitmq_username
}

output "rabbitmq_password" {
  description = "Senha do RabbitMQ"
  value       = random_password.rabbitmq_password.result
  sensitive   = true
} 