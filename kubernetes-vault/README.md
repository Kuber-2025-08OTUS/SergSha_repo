#### 1. Подключение к Yandex Cloud

Kubernetes кластер будем разворачивать с помощью Terraform на YandexCloud.

Перед установкой нужно убедиться, что все пакеты в системе обновлены: 
```bash
sudo apt update && sudo apt upgrade -y
```

Скачать скрипт установки с сайта storage.yandexcloud.net:
```bash
curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash
```

Запустить скачанный скрипт:
```bash
sudo source ./install_yc.sh
```

Для начала получаем OAUTH токен:
```
https://cloud.yandex.ru/docs/iam/concepts/authorization/oauth-token
```

Настраиваем аутентификации в консоли:
```bash
yc config set token <OAUTH-token>        # Вставляем свой OAUTH-токен
export YC_TOKEN=$(yc iam create-token)
export TF_VAR_yc_token=$YC_TOKEN
```

В файле input.auto.tfvars нужно вставить свой 'cloud_id' и 'folder_id':
```
yc_cloud_id  = "..."
yc_folder_id = "..." 
```

#### 2. Развертывание кластера Kubernetes

В директории **kubernetes-vault** выполнить следующую команду:
```bash
terraform -chdir=./terraform init && \
terraform -chdir=./terraform apply -auto-approve
```

#### 3. Установка Consul

Команда установки Consul:
```bash
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update
helm install consul hashicorp/consul -n consul --create-namespace -f terraform/charts/consul-values.yaml
```

#### 4. Установка Vault с Consul в качестве бэкенда

Команда установки Vault:
```bash
helm install vault hashicorp/vault -n vault --create-namespace -f terraform/charts/vault-values.yaml
```

#### 5. Инициализация Vault и распечатывание

Инициализация Vault:
```bash
kubectl exec -n vault vault-0 -- vault operator init -key-shares=1 -key-threshold=1 -format=json > vault-keys.json
```

Получение unseal key и root token:
```bash
UNSEAL_KEY=$(cat vault-keys.json | jq -r ".unseal_keys_b64[]")
ROOT_TOKEN=$(cat vault-keys.json | jq -r ".root_token")
```

Распечатывание всех подов Vault:
```bash
kubectl exec -n vault vault-0 -- vault operator unseal $UNSEAL_KEY
kubectl exec -n vault vault-1 -- vault operator unseal $UNSEAL_KEY
kubectl exec -n vault vault-2 -- vault operator unseal $UNSEAL_KEY
```

#### 6. Создание секрета в Vault

Логин в Vault:
```bash
kubectl exec -n vault vault-0 -- vault login $ROOT_TOKEN
```

Включение KV секретов:
```bash
kubectl exec -n vault vault-0 -- vault secrets enable -path=otus kv-v2
```

Создание секрета **otus/cred**:
```bash
kubectl exec -n vault vault-0 -- vault kv put otus/cred username=otus password=asajkjkahs
```

#### 7. ServiceAccount и ClusterRoleBinding

Создание сервисного аккаунта **sa-vault**:
```bash
kubectl apply -f kubernetes/sa-vault.yaml
```

Создание ClusterRoleBinding **auth-delegator**:
```bash
kubectl apply -f kubernetes/crb-auth-delegator.yaml
```

#### 8. Настройка Kubernetes Auth в Vault

Включение метода kubernetes в движке auth:
```bash
kubectl exec -n vault vault-0 -- vault auth enable kubernetes
```

Получение JWT токена и CA сертификата:
```bash
kubectl exec -n vault vault-0 -- sh -c 'vault write auth/kubernetes/config \
  token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
  kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443" \
  kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt'
```

#### 9. Создание политики Vault

Применение политики **otus-policy**:
```bash
cat otus-policy.hcl | kubectl exec -n vault vault-0 -i -- vault policy write otus-policy -
```

#### 10. Создание роли в Vault

```bash
kubectl exec -n vault vault-0 -- vault write auth/kubernetes/role/otus \
  bound_service_account_names=vault-auth \
  bound_service_account_namespaces=vault \
  policies=otus-policy \
  # audience="vault" \
  ttl=24h
```

#### 11. Установка External Secrets Operator

Команда установки External Secrets Operator:
```bash
helm repo add external-secrets https://charts.external-secrets.io
helm repo update
helm install external-secrets external-secrets/external-secrets -n external-secrets --create-namespace -f terraform/charts/external-secrets-values.yaml
```
<!-- ```bash
helm upgrade --install external-secrets \
  external-secrets/external-secrets \
  -n external-secrets \
  --create-namespace \
  --set installCRDs=true
``` -->

#### 12. Создание SecretStore

```bash
kubectl apply -f kubernetes/secretstore.yaml
```

#### 13. Создание ExternalSecret

```bash
kubectl apply -f kubernetes/external-secrets.yaml
```

#### 14. Установка Ingress

В качестве балансировщика будем использовать Ingress-Nginx:
```bash
kubectl apply -f kubernetes/ingress-nginx.yaml
```

Добавить строку в /etc/hosts (добавляем внешний ip адрес балансировщика YandexCloud):
```bash
echo $(kubectl get service/ingress-nginx-controller -n ingress-nginx -o "jsonpath={.status.loadBalancer.ingress[0].ip}") homework.otus vault.homework.otus consul.homework.otus | sudo tee -a /etc/hosts
```

В браузере можно войти в веб-версию Vault пройдя по ссылке:
```
http://vault.homework.otus
```
![alt text](<pics/Screenshot from 2025-11-03 20-30-53.png>)

![alt text](<pics/Screenshot from 2025-11-03 20-31-04.png>) 

![alt text](<pics/Screenshot from 2025-11-03 20-31-35.png>) 

![alt text](<pics/Screenshot from 2025-11-03 20-31-46.png>)

И также можно войти в веб-версию Consul пройдя по ссылке:
```
http://consul.homework.otus
```
![alt text](<pics/Screenshot from 2025-11-03 20-28-23.png>)

#### Проверка результата

Проверка созданного секрета
```bash
kubectl get secret -n vault otus-cred -o yaml
```

Декодирование и проверка значений
```bash
kubectl get secret -n vault otus-cred -o jsonpath='{.data.username}' | base64 --decode ; echo
kubectl get secret -n vault otus-cred -o jsonpath='{.data.password}' | base64 --decode ; echo
```

Все необходимые файлы конфигурации и команды предоставлены. После выполнения всех шагов должна быть полностью рабочая система с Vault, использующая Consul в качестве бэкенда хранения, и External Secrets Operator для синхронизации секретов в Kubernetes.

