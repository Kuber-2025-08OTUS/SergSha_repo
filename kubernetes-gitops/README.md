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

В качестве балансировщика будем использовать Ingress-Nginx:
```bash
kubectl apply -f ingress-nginx.yaml
```

Добавить строку в /etc/hosts (добавляем внешний ip адрес балансировщика YandexCloud):
```bash
echo $(kubectl get service/ingress-nginx-controller -n ingress-nginx -o "jsonpath={.status.loadBalancer.ingress[0].ip}") homework.otus argocd.homework.otus network.homework.otus templating.homework.otus | sudo tee -a /etc/hosts
```

или
```bash
echo $(yc load-balancer network-load-balancer list --folder-id $(terraform output -raw folder_id) --format json |  jq -r '.[0].listeners[0].address') homework.otus argocd.homework.otus network.homework.otus templating.homework.otus | sudo tee -a /etc/hosts
```

Получить пароль для входа в argocd в браузере:
```bash
kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```

Пройти по ссылке в браузере:
```
https://argocd.homework.otus
```

Сгенерируем ключ для доступа в github.com из argocd:
```bash
ssh-keygen -t ed25519 -f argocd -N ""
```

Скопируем содержимое публичного ключа argocd.pub и вставляем в github.com:
```bash
cat argocd.pub
```

<Your_Profile> -> Setting -> SSH and GPG keys -> New SSH key
Title: argocd
Key type: Authentication Key
Key: <Public SSH Key>

Скопируем содержимое публичного ключа argocd.pub и вставляем в argocd:
```bash
cat argocd
```

Setting -> Repositories -> CONNECT REPO 
Choose your connection method: VIA SSH
Name: argocd
Project: otus
Repository URL: git@github.com:Kuber-2025-08OTUS/SergSha_repo.git
SSH private key data: <Private SSH Key>

Нажимаем CONNECT



```bash
kubectl apply -f argocd-project.yaml
kubectl apply -f app-kubernetes-networks.yaml
kubectl apply -f app-kubernetes-templating.yaml
```


После развертывания выполнить:

```bash
kubectl get node -o wide --show-labels
```
```
NAME                        STATUS   ROLES    AGE    VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME     LABELS
cl15uu8ehu4ufnepn2g1-ahol   Ready    <none>   111m   v1.30.1   10.10.0.31    <none>        Ubuntu 20.04.6 LTS   5.4.0-216-generic   containerd://1.7.25   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/instance-type=standard-v3,beta.kubernetes.io/os=linux,failure-domain.beta.kubernetes.io/zone=ru-central1-d,kubernetes.io/arch=amd64,kubernetes.io/hostname=cl15uu8ehu4ufnepn2g1-ahol,kubernetes.io/os=linux,node-role=infra,node.kubernetes.io/instance-type=standard-v3,node.kubernetes.io/kube-proxy-ds-ready=true,node.kubernetes.io/masq-agent-ds-ready=true,node.kubernetes.io/node-problem-detector-ds-ready=true,topology.kubernetes.io/zone=ru-central1-d,yandex.cloud/node-group-id=catj1i90iu6q1ae9obbs,yandex.cloud/pci-topology=k8s,yandex.cloud/preemptible=false
cl1buk59kess38o2a2i6-iriz   Ready    <none>   111m   v1.30.1   10.10.0.29    <none>        Ubuntu 20.04.6 LTS   5.4.0-216-generic   containerd://1.7.25   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/instance-type=standard-v3,beta.kubernetes.io/os=linux,failure-domain.beta.kubernetes.io/zone=ru-central1-d,kubernetes.io/arch=amd64,kubernetes.io/hostname=cl1buk59kess38o2a2i6-iriz,kubernetes.io/os=linux,node.kubernetes.io/instance-type=standard-v3,node.kubernetes.io/kube-proxy-ds-ready=true,node.kubernetes.io/masq-agent-ds-ready=true,node.kubernetes.io/node-problem-detector-ds-ready=true,topology.kubernetes.io/zone=ru-central1-d,yandex.cloud/node-group-id=cat3hdv9umd3ngquua2l,yandex.cloud/pci-topology=k8s,yandex.cloud/preemptible=false
```

```bash
kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints
```
```
NAME                        TAINTS
cl15uu8ehu4ufnepn2g1-ahol   [map[effect:NoSchedule key:node-role value:infra]]
cl1buk59kess38o2a2i6-iriz   <none>
```

Проверить, что проект otus создался:
```bash
kubectl get appproject -n argocd
kubectl describe appproject otus -n argocd
```


-------------------------------------------
Events:
  Type    Reason                Age                   From                         Message
  ----    ------                ----                  ----                         -------
  Normal  ExternalProvisioning  95s (x26 over 7m48s)  persistentvolume-controller  Waiting for a volume to be created either by the external provisioner ###'k8s.io/minikube-hostpath'### or manually by the system administrator. If volume creation is delayed, please verify that the provisioner is running and correctly registered.
-------------------------------------------



Все конфигурации гарантируют, что:
- ArgoCD компоненты устанавливаются только на infra-ноды
- Приложения разворачиваются в правильные namespace
- Для helm-чарта переопределяется количество реплик
- Настроены правильные политики синхронизации


helm install my-release chart-name \
  --set provisioner=yandex.csi.flant.com \
  --set parameters.type=network-ssd

helm install yc-storage . \
  --set name=yc-network-ssd \
  --set provisioner=yandex.csi.flant.com \
  --set parameters.type=network-ssd \
  --set reclaimPolicy=Delete \
  --set volumeBindingMode=WaitForFirstConsumer

# Установка самого CSI driver
kubectl apply -f https://raw.githubusercontent.com/yandex-cloud/k8s-csi-sys/master/deploy/yc-disk-csi-driver.yaml

# Затем создание StorageClass через Helm или manifest

# Проверить StorageClass
kubectl get storageclass

# Проверить параметры
kubectl describe storageclass yc-network-ssd