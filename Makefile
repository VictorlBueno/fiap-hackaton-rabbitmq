.PHONY: help deploy destroy status logs port-forward clean

help: ## Mostra esta ajuda
	@echo "Comandos disponíveis:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

deploy: ## Deploy do RabbitMQ no Kubernetes
	cd k8s && kubectl apply -k .

destroy: ## Remove o RabbitMQ do Kubernetes
	cd k8s && kubectl delete -k .

status: ## Mostra o status dos recursos do RabbitMQ
	@echo "=== Pods ==="
	kubectl get pods -n rabbitmq
	@echo ""
	@echo "=== Services ==="
	kubectl get svc -n rabbitmq
	@echo ""
	@echo "=== PVCs ==="
	kubectl get pvc -n rabbitmq
	@echo ""
	@echo "=== Cluster Status ==="
	kubectl exec -n rabbitmq rabbitmq-0 -- rabbitmqctl cluster_status 2>/dev/null || echo "Cluster ainda não está pronto"

logs: ## Mostra os logs do RabbitMQ
	kubectl logs -n rabbitmq -l app=rabbitmq --tail=50 -f

logs-node: ## Mostra logs de um nó específico (use NODE=0,1,2)
	kubectl logs -n rabbitmq rabbitmq-$(NODE) --tail=50 -f

port-forward: ## Faz port-forward para a interface web
	kubectl port-forward -n rabbitmq svc/rabbitmq-management 15672:15672

port-forward-amqp: ## Faz port-forward para AMQP
	kubectl port-forward -n rabbitmq svc/rabbitmq 5672:5672

clean: ## Remove recursos órfãos
	kubectl delete pvc -n rabbitmq --all --ignore-not-found=true

restart: ## Reinicia o StatefulSet
	kubectl rollout restart statefulset/rabbitmq -n rabbitmq

scale: ## Escala o cluster (use REPLICAS=5)
	kubectl scale statefulset rabbitmq -n rabbitmq --replicas=$(REPLICAS)

get-credentials: ## Mostra as credenciais do RabbitMQ
	@echo "Usuário: admin"
	@echo "Senha: admin123"
	@echo "Host: rabbitmq.rabbitmq.svc.cluster.local"
	@echo "Port: 5672"

test-connection: ## Testa conexão AMQP (requer amqp-tools)
	kubectl port-forward -n rabbitmq svc/rabbitmq 5672:5672 &
	sleep 2
	amqp-declare-queue -u amqp://admin:admin123@localhost:5672/ -q test-queue || echo "Conexão falhou"
	pkill -f "port-forward.*5672"

install-ebs-csi: ## Instala o AWS EBS CSI Driver
	kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/?ref=release-1.21"

install-ingress: ## Instala o NGINX Ingress Controller
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/aws/deploy.yaml 