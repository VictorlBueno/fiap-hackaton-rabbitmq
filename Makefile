.PHONY: help init plan apply destroy output clean deploy

help: ## Mostra esta ajuda
	@echo "Comandos disponíveis:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

init: ## Inicializa o Terraform
	cd terraform && terraform init

plan: ## Executa o plan do Terraform
	cd terraform && terraform plan

apply: ## Aplica as mudanças do Terraform
	cd terraform && terraform apply -auto-approve

destroy: ## Destroi a infraestrutura
	cd terraform && terraform destroy -auto-approve

output: ## Mostra os outputs do Terraform
	cd terraform && terraform output

validate: ## Valida os arquivos do Terraform
	cd terraform && terraform validate

fmt: ## Formata os arquivos do Terraform
	cd terraform && terraform fmt -recursive

clean: ## Remove arquivos temporários
	cd terraform && rm -rf .terraform .terraform.lock.hcl

deploy: init plan apply output ## Deploy completo do RabbitMQ

get-credentials: ## Obtém as credenciais do RabbitMQ do Secrets Manager
	aws secretsmanager get-secret-value --secret-id fiap-hack/rabbitmq-credentials --query SecretString --output text | jq -r '.amqp_url'

test-connection: ## Testa a conexão com o RabbitMQ
	@echo "=== Testando conexão com o RabbitMQ ==="
	@echo "Host: $(shell cd terraform && terraform output -raw rabbitmq_private_ip)"
	@echo "Porta AMQP: 5672"
	@echo "Porta Management: 15672"
	@echo ""
	@echo "Para testar a conexão AMQP, use:"
	@echo "aws secretsmanager get-secret-value --secret-id fiap-hack/rabbitmq-credentials --query SecretString --output text | jq -r '.amqp_url'"
	@echo ""
	@echo "Para acessar a interface de gerenciamento:"
	@echo "http://$(shell cd terraform && terraform output -raw rabbitmq_private_ip):15672"

status: ## Mostra o status da instância RabbitMQ
	@echo "=== Status da Instância RabbitMQ ==="
	@echo "Instance ID: $(shell cd terraform && terraform output -raw rabbitmq_instance_id)"
	@echo "Private IP: $(shell cd terraform && terraform output -raw rabbitmq_private_ip)"
	@echo "Management URL: $(shell cd terraform && terraform output -raw rabbitmq_management_url)"
	@echo ""
	@echo "Status da instância:"
	aws ec2 describe-instances --instance-ids $(shell cd terraform && terraform output -raw rabbitmq_instance_id) --query 'Reservations[0].Instances[0].State.Name' --output text

logs: ## Mostra informações sobre logs do RabbitMQ
	@echo "=== Logs do RabbitMQ ==="
	@echo "Para acessar os logs, use o console AWS ou CloudWatch:"
	@echo "1. Acesse o console AWS EC2"
	@echo "2. Selecione a instância: $(shell cd terraform && terraform output -raw rabbitmq_instance_id)"
	@echo "3. Vá em 'Actions' > 'Monitor and troubleshoot' > 'Get system log'"
	@echo ""
	@echo "Ou use CloudWatch Logs se configurado."

restart: ## Reinicia a instância RabbitMQ
	aws ec2 reboot-instances --instance-ids $(shell cd terraform && terraform output -raw rabbitmq_instance_id)
	@echo "Instância sendo reiniciada..."



get-management-url: ## Obtém a URL da interface de gerenciamento
	@echo "Interface de Gerenciamento: $(shell cd terraform && terraform output -raw rabbitmq_management_url)"
	@echo "Usuário: admin"
	@echo "Senha: $(shell aws secretsmanager get-secret-value --secret-id fiap-hack/rabbitmq-credentials --query SecretString --output text | jq -r '.password')" 