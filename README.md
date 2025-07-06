### Componentes Criados

- **Namespace**: `rabbitmq` para isolamento
- **StatefulSet**: 3 réplicas do RabbitMQ
- **Services**: 
  - `rabbitmq`: Headless service para cluster
  - `rabbitmq-management`: Service para interface web
- **Storage**: Persistent volumes com EBS
- **ConfigMap**: Configurações do RabbitMQ
- **Secret**: Credenciais seguras
- **Ingress**: Acesso externo à interface de gerenciamento

### Características

- **Cluster**: 3 nós para alta disponibilidade
- **Persistência**: Dados armazenados em EBS
- **Escalável**: Fácil de escalar horizontalmente
- **Monitoramento**: Interface web de gerenciamento
- **Seguro**: Credenciais em Kubernetes Secrets

## Pré-requisitos

- Cluster Kubernetes (EKS recomendado)
- kubectl configurado
- AWS EBS CSI Driver instalado
- NGINX Ingress Controller (opcional)

## Configuração

1. **Certifique-se que o cluster Kubernetes está funcionando**:
   ```bash
   kubectl cluster-info
   ```

2. **Instale o AWS EBS CSI Driver** (se necessário):
   ```bash
   kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/?ref=release-1.21"
   ```

## Deploy

```bash
cd k8s
kubectl apply -k .
```

## Verificar Status

```bash
# Verificar pods
kubectl get pods -n rabbitmq

# Verificar services
kubectl get svc -n rabbitmq

# Verificar cluster status
kubectl exec -n rabbitmq rabbitmq-0 -- rabbitmqctl cluster_status
```

## Acessar Interface Web

```bash
# Port-forward para acesso local
kubectl port-forward -n rabbitmq svc/rabbitmq-management 15672:15672
```

Acesse: http://localhost:15672
- Usuário: `admin`
- Senha: `admin123`

## Destruir

```bash
cd k8s
kubectl delete -k .
```

## Configurações

### Credenciais Padrão
- **Usuário**: `admin`
- **Senha**: `admin123`
- **VHost**: `/`

### Portas
- **AMQP**: 5672
- **Management**: 15672

### Storage
- **Tipo**: EBS GP2
- **Tamanho**: 1Gi por pod
- **Expansão**: Habilitada

## Monitoramento

O RabbitMQ inclui:
- Health checks automáticos
- Interface web de gerenciamento
- Logs estruturados
- Métricas de performance

## Escalabilidade

Para escalar o cluster:
```bash
kubectl scale statefulset rabbitmq -n rabbitmq --replicas=5
```

## Segurança

- Credenciais armazenadas em Kubernetes Secrets
- Network policies podem ser aplicadas
- Interface web protegida por autenticação básica
- Comunicação interna criptografada