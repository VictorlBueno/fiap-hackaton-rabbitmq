# RabbitMQ - AWS Infrastructure

Este módulo provisiona uma instância RabbitMQ na AWS usando Terraform, integrada com a VPC do projeto.

## Arquitetura

- **Instância EC2**: Amazon Linux 2 com RabbitMQ instalado
- **Security Group**: Configurado para permitir tráfego AMQP (5672) e Management UI (15672)
- **Secrets Manager**: Armazena credenciais de forma segura
- **VPC**: Utiliza a VPC criada pelo módulo `/vpc`
- **Subnet**: Instância em subnet privada para segurança
- **Terraform**: Infraestrutura como código consistente com o projeto

## Pré-requisitos

1. VPC criada (`/vpc`)
2. AWS CLI configurado
3. Terraform instalado

## Deploy

### 1. Deploy completo
```bash
make deploy
```

### 2. Verificar status
```bash
make status
```

## Comandos Disponíveis

### Terraform
- `make init` - Inicializar Terraform
- `make plan` - Gerar plano
- `make apply` - Aplicar mudanças
- `make destroy` - Destruir infraestrutura
- `make output` - Mostrar outputs
- `make validate` - Validar configuração
- `make fmt` - Formatar arquivos

### Operações
- `make deploy` - Deploy completo
- `make status` - Status da instância
- `make logs` - Instruções para acessar logs
- `make restart` - Reiniciar instância
- `make get-credentials` - Obter credenciais do Secrets Manager
- `make test-connection` - Testar conexão
- `make get-management-url` - URL da interface de gerenciamento

## Configuração

### Variáveis principais
- `rabbitmq_instance_type`: Tipo de instância EC2 (padrão: t3.micro)
- `rabbitmq_volume_size`: Tamanho do volume EBS em GB (padrão: 20)
- `rabbitmq_username`: Usuário do RabbitMQ (padrão: admin)


### Security Groups
- **AMQP**: Porta 5672 (apenas do cluster EKS)
- **Management UI**: Porta 15672 (apenas do cluster EKS)
- **SSH**: Porta 22 (apenas do cluster EKS)

## Integração com Service

O módulo `/service` está configurado para:
1. Buscar credenciais automaticamente do Secrets Manager
2. Usar a URL AMQP completa para conexão
3. Configurar variáveis de ambiente no Kubernetes

### Variáveis de ambiente no Service
- `RABBITMQ_URL`: URL AMQP completa
- `RABBITMQ_HOST`: Host da instância
- `RABBITMQ_PORT`: Porta AMQP (5672)
- `RABBITMQ_USERNAME`: Usuário
- `RABBITMQ_PASSWORD`: Senha

## Monitoramento

### Interface de Gerenciamento
- URL: `http://[PRIVATE_IP]:15672`
- Usuário: admin
- Senha: Gerada automaticamente e armazenada no Secrets Manager

### Logs
Para acessar os logs da instância:
1. Acesse o console AWS EC2
2. Selecione a instância RabbitMQ
3. Vá em 'Actions' > 'Monitor and troubleshoot' > 'Get system log'
4. Ou use CloudWatch Logs se configurado

## Segurança

- Instância em subnet privada
- Security group restritivo
- Credenciais armazenadas no Secrets Manager
- Senha gerada automaticamente
- Firewall local configurado
