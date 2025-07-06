#!/bin/bash

# Atualizar o sistema
yum update -y

# Instalar dependências
yum install -y wget curl

# Adicionar repositório Erlang
cat > /etc/yum.repos.d/rabbitmq-erlang.repo << EOF
[rabbitmq_erlang]
name=rabbitmq_erlang
baseurl=https://packagecloud.io/rabbitmq/erlang/el/7/\$basearch
repo_gpgcheck=1
gpgcheck=0
enabled=1
gpgkey=https://packagecloud.io/rabbitmq/erlang/gpgkey
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
metadata_expire=300
EOF

# Adicionar repositório RabbitMQ
cat > /etc/yum.repos.d/rabbitmq.repo << EOF
[rabbitmq_server]
name=rabbitmq_server
baseurl=https://packagecloud.io/rabbitmq/rabbitmq-server/el/7/\$basearch
repo_gpgcheck=1
gpgcheck=0
enabled=1
gpgkey=https://packagecloud.io/rabbitmq/rabbitmq-server/gpgkey
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
metadata_expire=300
EOF

# Instalar Erlang e RabbitMQ
yum install -y erlang rabbitmq-server

# Iniciar e habilitar o RabbitMQ
systemctl start rabbitmq-server
systemctl enable rabbitmq-server

# Aguardar o RabbitMQ inicializar
sleep 10

# Criar usuário e definir permissões
rabbitmqctl add_user ${rabbitmq_username} ${rabbitmq_password}
rabbitmqctl set_user_tags ${rabbitmq_username} administrator
rabbitmqctl set_permissions -p / ${rabbitmq_username} ".*" ".*" ".*"

# Habilitar plugin de gerenciamento
rabbitmq-plugins enable rabbitmq_management

# Reiniciar o RabbitMQ para aplicar as mudanças
systemctl restart rabbitmq-server

# Configurar firewall local
systemctl start firewalld
systemctl enable firewalld
firewall-cmd --permanent --add-port=5672/tcp
firewall-cmd --permanent --add-port=15672/tcp
firewall-cmd --reload

# Criar diretório para logs
mkdir -p /var/log/rabbitmq
chown rabbitmq:rabbitmq /var/log/rabbitmq

# Configurar logrotate
cat > /etc/logrotate.d/rabbitmq << EOF
/var/log/rabbitmq/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 rabbitmq rabbitmq
    postrotate
        systemctl reload rabbitmq-server > /dev/null 2>&1 || true
    endscript
}
EOF

echo "RabbitMQ instalado e configurado com sucesso!"
echo "Usuário: ${rabbitmq_username}"
echo "Host: $(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)"
echo "Porta AMQP: 5672"
echo "Porta Management: 15672" 