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

В директории **kubernetes-csi** выполнить следующую команду:
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
kubectl apply -f kubernetes/ingress.yaml
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

Object Storage -> Бакеты -> bucket-s3-01 -> pvc...

![alt text](<pics/Screenshot from 2025-11-18 21-59-24.png>)

![alt text](<pics/Screenshot from 2025-11-18 21-59-55.png>)

![alt text](<pics/Screenshot from 2025-11-18 22-00-22.png>)


Также можно пройти по ссылке, чтобы убедиться, что всё работает:
```
http://homework.otus
```

![alt text](<pics/Screenshot from 2025-11-18 22-13-33.png>)


Все необходимые манифесты предоставлены и соответствуют требованиям задания.
