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

![alt text](<pics/Screenshot from 2025-10-23 23-25-44.png>)

Убедиться, что подключение к репозитории github.com имеет статус Successful

![alt text](<pics/Screenshot from 2025-10-23 23-35-13.png>)

Запустить следующие команды:
- создать проект otus:
```bash
kubectl apply -f argocd-project.yaml
```

- создать приложение kubernetes-networks:
```bash
kubectl apply -f app-kubernetes-networks.yaml
```

- создать приложение kubernetes-templating:
```bash
kubectl apply -f app-kubernetes-templating.yaml
```

После развертывания выполнить для проверки:
```bash
kubectl get node -o wide --show-labels
```
```
NAME                        STATUS   ROLES    AGE    VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME     LABELS
cl1a0l9v65916hkp0k0s-atix   Ready    <none>   127m   v1.30.1   10.10.0.26    <none>        Ubuntu 20.04.6 LTS   5.4.0-216-generic   containerd://1.7.25   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/instance-type=standard-v3,beta.kubernetes.io/os=linux,failure-domain.beta.kubernetes.io/zone=ru-central1-d,kubernetes.io/arch=amd64,kubernetes.io/hostname=cl1a0l9v65916hkp0k0s-atix,kubernetes.io/os=linux,node-role=infra,node.kubernetes.io/instance-type=standard-v3,node.kubernetes.io/kube-proxy-ds-ready=true,node.kubernetes.io/masq-agent-ds-ready=true,node.kubernetes.io/node-problem-detector-ds-ready=true,topology.kubernetes.io/zone=ru-central1-d,yandex.cloud/node-group-id=cati8m9s771ole4am6ap,yandex.cloud/pci-topology=k8s,yandex.cloud/preemptible=false
cl1msl5oumhq5k062fg1-yvas   Ready    <none>   126m   v1.30.1   10.10.0.11    <none>        Ubuntu 20.04.6 LTS   5.4.0-216-generic   containerd://1.7.25   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/instance-type=standard-v3,beta.kubernetes.io/os=linux,failure-domain.beta.kubernetes.io/zone=ru-central1-d,homework=true,kubernetes.io/arch=amd64,kubernetes.io/hostname=cl1msl5oumhq5k062fg1-yvas,kubernetes.io/os=linux,node-role=workload,node.kubernetes.io/instance-type=standard-v3,node.kubernetes.io/kube-proxy-ds-ready=true,node.kubernetes.io/masq-agent-ds-ready=true,node.kubernetes.io/node-problem-detector-ds-ready=true,topology.kubernetes.io/zone=ru-central1-d,yandex.cloud/node-group-id=catpapa7ja0hhobncdg5,yandex.cloud/pci-topology=k8s,yandex.cloud/preemptible=false
```

```bash
kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints
```
```
NAME                        TAINTS
cl1a0l9v65916hkp0k0s-atix   [map[effect:NoSchedule key:node-role value:infra]]
cl1msl5oumhq5k062fg1-yvas   <none>
```

Проверить, что проект otus создался:
```bash
kubectl get appproject -n argocd
```
```
NAME      AGE
default   126m
otus      93m
```

```bash
kubectl describe appproject otus -n argocd
```
```
Name:         otus
Namespace:    argocd
Labels:       <none>
Annotations:  <none>
API Version:  argoproj.io/v1alpha1
Kind:         AppProject
Metadata:
  Creation Timestamp:  2025-10-23T17:50:23Z
  Finalizers:
    resources-finalizer.argocd.argoproj.io
  Generation:        1
  Resource Version:  10845
  UID:               f3b0afc4-550a-49c7-ad51-4b9ba929cc52
Spec:
  Cluster Resource Whitelist:
    Group:      *
    Kind:       *
  Description:  OTUS Homework Project
  Destinations:
    Namespace:  homework
    Server:     https://kubernetes.default.svc
    Namespace:  homeworkhelm
    Server:     https://kubernetes.default.svc
  Namespace Resource Whitelist:
    Group:  *
    Kind:   *
  Roles:
    Description:  Read-only access to OTUS applications
    Groups:
      otus-students
    Name:  read-only
    Policies:
      p, proj:otus:read-only, applications, get, otus/*, allow
  Source Repos:
    git@github.com:Kuber-2025-08OTUS/SergSha_repo.git
Events:  <none>
```

![alt text](<pics/Screenshot from 2025-10-23 23-26-51.png>)

Проверить все работающие ресурсы в пространстве имён homework:
```bash
kubectl get all -n homework
```
```
NAME                                    READY   STATUS    RESTARTS   AGE
pod/nginx-deployment-77cfb74575-9l7kk   1/1     Running   0          143m
pod/nginx-deployment-77cfb74575-fjrkq   1/1     Running   0          143m
pod/nginx-deployment-77cfb74575-zwjwl   1/1     Running   0          143m

NAME                  TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
service/web-service   ClusterIP   10.96.205.56   <none>        8080/TCP   143m

NAME                               READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx-deployment   3/3     3            3           143m

NAME                                          DESIRED   CURRENT   READY   AGE
replicaset.apps/nginx-deployment-77cfb74575   3         3         3       143m
```

```bash
kubectl get ingress -n homework
```
```
NAME          CLASS   HOSTS                   ADDRESS          PORTS   AGE
web-ingress   nginx   network.homework.otus   130.193.59.123   80      145m
```

Проверить все работающие ресурсы в пространстве имён homeworkhelm:
```bash
kubectl get all -n homeworkhelm
```
```
NAME                               READY   STATUS    RESTARTS   AGE
pod/web-postgres-0                 1/1     Running   0          83m
pod/web-webchart-f985f48fc-6kwbw   1/1     Running   0          83m
pod/web-webchart-f985f48fc-9w8cx   1/1     Running   0          83m
pod/web-webchart-f985f48fc-n27v8   1/1     Running   0          83m

NAME                   TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
service/web-postgres   ClusterIP   10.96.244.201   <none>        5432/TCP   83m
service/web-webchart   ClusterIP   10.96.221.175   <none>        8080/TCP   83m

NAME                           READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/web-webchart   3/3     3            3           83m

NAME                                     DESIRED   CURRENT   READY   AGE
replicaset.apps/web-webchart-f985f48fc   3         3         3       83m

NAME                            READY   AGE
statefulset.apps/web-postgres   1/1     83m
```

```bash
kubectl get ingress -n homeworkhelm
```
```
NAME           CLASS   HOSTS                      ADDRESS          PORTS   AGE
web-webchart   nginx   templating.homework.otus   130.193.59.123   80      84m
```

Пройти в браузере по ссылке:
```
https://argocd.homework.otus
```

![alt text](<pics/Screenshot from 2025-10-23 22-04-27.png>)

![alt text](<pics/Screenshot from 2025-10-23 22-06-00.png>)

![alt text](<pics/Screenshot from 2025-10-23 22-06-36.png>)


Можно пройтись в браузере по следующим ссылкам:
```
http://network.homework.otus
```
```
http://templating.homework.otus
```


Все конфигурации гарантируют, что:
- ArgoCD компоненты устанавливаются только на infra-ноды
- Приложения разворачиваются в правильные namespace
- Для helm-чарта переопределяется количество реплик
- Настроены правильные политики синхронизации
