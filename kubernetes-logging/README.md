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

Выполнить следующую команду:
```bash
terraform init && terraform apply -auto-approve
```

В качестве балансировщика будем использовать Contour Ingress (https://projectcontour.io/):
```bash
kubectl apply -f https://projectcontour.io/quickstart/contour.yaml
```
```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx
```

Получить ключи:
```bash
ACCESS_KEY=$(terraform output -raw loki_access_key)
SECRET_KEY=$(terraform output -raw loki_secret_key)
```

Создать namespace loki:
```bash
kubectl create ns loki
```

Создать secret в Kubernetes
```bash
kubectl create secret generic loki-bucket-creds -n loki \
  --from-literal=access-key-id=$ACCESS_KEY \
  --from-literal=access-key-secret=$SECRET_KEY \
  --dry-run=client -o yaml | kubectl apply -f -
```

Добавить репозиторий Grafana chart в Helm:
```bash
helm repo add grafana https://grafana.github.io/helm-charts
```

Обновить репозиторий Helm:
```bash
helm repo update
```

Установить Loki, используя файл конфигурации loki-values.yaml:
```bash
helm upgrade --install loki grafana/loki -f charts/loki-values.yaml -n loki #--create-namespace
```

Установить promtail:
```bash
helm upgrade --install promtail grafana/promtail -f charts/promtail-values.yaml -n loki
```

Установить Grafana:
```bash
helm upgrade --install grafana grafana/grafana -f charts/grafana-values.yaml -n loki
```

В качестве балансировщика будем использовать Ingress-Nginx:
```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx
kubectl apply -f ingress.yaml
```

или Contour Ingress (https://projectcontour.io/):
```bash
kubectl apply -f https://projectcontour.io/quickstart/contour.yaml
kubectl apply -f ingress.yaml
```

Добавить строку в /etc/hosts (добавляем внешний ip адрес балансировщика YandexCloud):
```bash
echo $(yc load-balancer network-load-balancer list --folder-id $(terraform output -raw folder_id) --format json |  jq -r '.[0].listeners[0].address') homework.otus loki.homework.otus grafana.homework.otus | sudo tee -a /etc/hosts
```

После развертывания выполнить:

```bash
kubectl get node -o wide --show-labels
```

```bash
kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints
```

Получить пароль Grafana:
```bash
kubectl get secret -n loki grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

Открыть в браузере http://grafana.homework.otus, войти с логином `admin` и полученным паролем.

Создать дашборд (импорт готового дашборда):
  Dashboards → New → Import
  Ввести ID: 18042 (официальный Loki dashboard)
  Выбрать datasource "Loki"
  Import

Можно также открыть в браузере http://loki.homework.otus/metrics, где можем увидеть метрики.
