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

После развёртывания kubernetes кластера из шаблона **./terraform/templates/secret.yaml.tftpl** создастся secret манифест **./kubernetes/secret.yaml**


#### 3. Получение доступа к s3 хранилищу (бакету)

Создать namespace homework:
```bash
kubectl create ns homework
```

Создать secret в Kubernetes из манифеста, созданного при разворачивании kubernetes кластера с помощью Terraform:
<!-- ```bash
kubectl create secret generic bucket-s3-creds -n homework \
  --from-literal=access-key-id=$ACCESS_KEY \
  --from-literal=access-key-secret=$SECRET_KEY \
  --dry-run=client -o yaml | kubectl apply -f -
``` -->
```bash
kubectl apply -f ./kubernetes/secret.yaml
```

Установить драйвер CSI с помощью Helm:
```bash
helm repo add yandex-s3 https://yandex-cloud.github.io/k8s-csi-s3/charts
helm repo update
helm install csi-s3 yandex-s3/csi-s3 -n kube-system \
  --set folderId=$(terraform -chdir=./terraform output -raw folder_id) \
  --set serviceAccountKey.secretName=bucket-s3-creds
```

Создать storageclass:
```bash
kubectl apply -f ./kubernetes/storageclass.yaml
```

Создать pvc:
```bash
kubectl apply -f ./kubernetes/pvc.yaml
```

Проверить, что pvc создался и имеет статус **bound**:
```bash
kubectl get pvc -n homework
```


#### 4. Установка дополнительных ресурсов для проверки CSI S3 бакета:

Развернуть deployment:
```bash
kubectl apply -f ./kubernetes/deployment.yaml
```

Установить service:
```bash
kubectl apply -f ./kubernetes/service.yaml
```


#### 5. Установка Ingress

В качестве балансировщика будем использовать Contour:
```bash
helm repo add contour https://projectcontour.github.io/helm-charts/
helm repo update
helm install contour contour/contour -n projectcontour --create-namespace
```

```bash
kubectl apply -f kubernetes/contour.yaml
```

Добавить строку в /etc/hosts (добавляем внешний ip адрес балансировщика YandexCloud):
```bash
echo $(kubectl get svc contour-envoy -n projectcontour -o "jsonpath={.status.loadBalancer.ingress[0].ip}") homework.otus | sudo tee -a /etc/hosts
```


#### 6. Проверка результата

Вывод списка подов:
```bash
kubectl get po -n homework
```

Вывод информации, например, первого из списка пода, чтобы убедиться, что s3 хранилище примонтировано (Mounts:):
```bash
kubectl describe po/$(kubectl get pods -n homework --no-headers -o custom-columns=":metadata.name" | sed -n 1p) -n homework
```

Вывод логов, например, первого из списка пода:
```bash
kubectl logs $(kubectl get pods -n homework --no-headers -o custom-columns=":metadata.name" | sed -n 1p) -n homework
```

Вывод списка storageclasses:
```bash
kubectl get storageclass -n homework
```

Вывод списка pvc:
```bash
kubectl get pvc -n homework
```

Вывод списка файлов в s3 хранилище (в данном случае должен быть файл **index.html**):
```bash
kubectl exec $(kubectl get pods -n homework --no-headers -o custom-columns=":metadata.name" | sed -n 1p) -c nginx -n homework -- ls -la /homework/
```

В браузере пройти по ссылке:
```
https://console.yandex.cloud/
```

Object Storage -> Бакеты -> bucket-s3-01

![alt text](<pics/Screenshot from 2025-11-18 21-59-24.png>)

![alt text](<pics/Screenshot from 2025-11-18 21-59-55.png>)

![alt text](<pics/Screenshot from 2025-11-18 22-00-22.png>)


Также можно пройти, что всё работает, по ссылке:
```
http://homework.otus
```

![alt text](<pics/Screenshot from 2025-11-18 22-13-33.png>)


Все необходимые манифесты предоставлены и соответствуют требованиям задания.













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

