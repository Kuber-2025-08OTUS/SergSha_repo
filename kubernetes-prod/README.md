### PART 1. CUSTOM KUBERNETES CLUSTER

#### 1.1. Подключение к Yandex Cloud

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

В файле **input.auto.tfvars** нужно вставить свой 'cloud_id' и 'folder_id':
```
yc = {
    cloud = {
        id = "..."
    }
    folder = {
        id   = "..."
    }
...
}
```

также имя пользователя 'user.name', публичный ssh ключ'user.ssh.public_key', приватный ssh ключ 'user.ssh.private_key':
```
user = {
    name = "..."
    ssh = {
        public_key  = "..."
        private_key = "..."
    }
}
```

#### 1.2. Создание виртуальных машин для развертывания кластера Kubernetes

Находясь в директории **kubernetes-prod** перейти в директорию **part1**:
```bash
cd ./part1
```

Далее выполнить команду:
```bash
terraform -chdir=./terraform init && \
terraform -chdir=./terraform apply -auto-approve
```

Получим четыре ноды, одна из которых будет **master**, остальные три - **worker**.

Из шаблонов в директории **./terraform/templates/** создадутся следующие файлы:
- ansible конфиг файл **./ansible/ansible.cfg**:
```
[defaults]
inventory = ./inventory.ini
remote_user = ubuntu
private_key_file = ~/.ssh/otus
host_key_checking = False
command_warnings = False
deprecation_warnings = False

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False

[ssh_connection]
ssh_args = -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyJump=ubuntu@158.160.214.15
```

- файл с переменными **./ansible/group_vars/all.yml**:
```
ansible_user: ubuntu

k8s:
    version:
        current: "1.33"
        upgrade: "1.34"
```

- inventory файл **./ansible/inventory.ini**:
```
[all]
master1 ansible_host=10.10.0.9
worker1 ansible_host=10.10.0.35
worker2 ansible_host=10.10.0.22
worker3 ansible_host=10.10.0.13

[master]
master1

[worker]
worker1
worker2
worker3
```


#### 1.3. Разворачивание кластера Kubernetes

Kubernetes будем разворачивать с помощью ansible-playbook.

Рекомендуется, чтобы убедиться, что все ноды доступны, предварительно запустить следующую команду:
```bash
ansible all -m ping
```

Разворачивать кластер Kubenetes с помощью ansible:
```bash
ansible-playbook k8s_setup.yml
```

Получим Kubernetes кластер версии **1.33**:
```bash
ansible master1 -m command -a 'kubectl get nodes -o wide --kubeconfig /home/ubuntu/.kube/config'
```
```
[WARNING]: Platform linux on host master1 is using the discovered Python interpreter at /usr/bin/python3.12, but future installation
of another Python interpreter could change the meaning of that path. See https://docs.ansible.com/ansible-
core/2.18/reference_appendices/interpreter_discovery.html for more information.
master1 | CHANGED | rc=0 >>
NAME       STATUS   ROLES           AGE     VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
master1   Ready    control-plane   2m18s   v1.33.6   10.10.0.9     <none>        Ubuntu 24.04.3 LTS   6.8.0-85-generic   containerd://1.7.28
worker1    Ready    <none>          62s     v1.33.6   10.10.0.35    <none>        Ubuntu 24.04.3 LTS   6.8.0-85-generic   containerd://1.7.28
worker2    Ready    <none>          62s     v1.33.6   10.10.0.22    <none>        Ubuntu 24.04.3 LTS   6.8.0-85-generic   containerd://1.7.28
worker3    Ready    <none>          62s     v1.33.6   10.10.0.13    <none>        Ubuntu 24.04.3 LTS   6.8.0-85-generic   containerd://1.7.28
```


#### 1.4. Обновление кластера Kubernetes

Обновить кластер Kubenetes с помощью следуюшей команды:
```bash
ansible-playbook k8s_upgrade.yml
```


#### 1.5. Проверка рехультата

Данный Kubernetes кластер должен обновиться до версии **1.34**, что можем проверить следующей командой:
```bash
ansible master1 -m command -a 'kubectl get nodes -o wide --kubeconfig /home/ubuntu/.kube/config'
```
```
[WARNING]: Platform linux on host master1 is using the discovered Python interpreter at /usr/bin/python3.12, but future installation
of another Python interpreter could change the meaning of that path. See https://docs.ansible.com/ansible-
core/2.18/reference_appendices/interpreter_discovery.html for more information.
master1 | CHANGED | rc=0 >>
NAME       STATUS   ROLES           AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
master1   Ready    control-plane   27m   v1.34.2   10.10.0.9     <none>        Ubuntu 24.04.3 LTS   6.8.0-85-generic   containerd://1.7.28
worker1    Ready    <none>          26m   v1.34.2   10.10.0.35    <none>        Ubuntu 24.04.3 LTS   6.8.0-85-generic   containerd://1.7.28
worker2    Ready    <none>          26m   v1.34.2   10.10.0.22    <none>        Ubuntu 24.04.3 LTS   6.8.0-85-generic   containerd://1.7.28
worker3    Ready    <none>          26m   v1.34.2   10.10.0.13    <none>        Ubuntu 24.04.3 LTS   6.8.0-85-generic   containerd://1.7.28
```



### PART 2. KUBESPRAY

#### 2.1. Установка

Находясь в директории **kubernetes-prod** перейти в директорию **part2**:
```bash
cd ./part2
```

Склонировать kubespray из github.com:
```bash
git clone https://github.com/kubernetes-sigs/kubespray.git
```

Создать виртуальную среду **venv**, установить необходимые пакеты и активировать виртуальную среду:
```bash
python3 -m venv venv
source ./venv/bin/activate
pip install -r kubespray/requirements.txt
```

Скопировать в директории **inventory** директорию **sample** в, например, **mycluster**:
```bash
cp -rfp kubespray/inventory/{sample,mycluster}
```


#### 2.2. Разворачивание виртуальных машин для Kubernetes кластера

Выполнить команду:
```bash
terraform -chdir=./terraform init && \
terraform -chdir=./terraform apply -auto-approve
```

Получим ansible конфиг файл **ansible.cfg**:
```bash
cat kubespray/ansible.cfg
```
```
[defaults]
# inventory = ./inventory.ini
# remote_user = ubuntu
private_key_file = ~/.ssh/otus
command_warnings = False

# https://github.com/ansible/ansible/issues/56930 (to ignore group names with - and .)
force_valid_group_names = ignore

host_key_checking=False
gathering = smart
fact_caching = jsonfile
fact_caching_connection = /tmp
fact_caching_timeout = 86400
timeout = 300
stdout_callback = default
display_skipped_hosts = no
library = ./library
callbacks_enabled = profile_tasks
roles_path = roles:$VIRTUAL_ENV/usr/local/share/kubespray/roles:$VIRTUAL_ENV/usr/local/share/ansible/roles:/usr/share/kubespray/roles
deprecation_warnings=False
inventory_ignore_extensions = ~, .orig, .bak, .ini, .cfg, .retry, .pyc, .pyo, .creds, .gpg

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False

[ssh_connection]
pipelining=True
ssh_args = -o ControlMaster=auto -o ControlPersist=30m -o ConnectionAttempts=100 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyJump=ubuntu@158.160.193.173
#control_path = ~/.ssh/ansible-%%r@%%h:%%p

[inventory]
ignore_patterns = artifacts, credentials
```

Получим inventory файл **inventory.ini**:
```bash
cat kubespray/inventory/mycluster/inventory.ini
```
```
[all]
master1 ansible_host=10.10.0.35 ip=10.10.0.35 etcd_member_name=etcd1
master2 ansible_host=10.10.0.27 ip=10.10.0.27 etcd_member_name=etcd2
master3 ansible_host=10.10.0.25 ip=10.10.0.25 etcd_member_name=etcd3
worker1 ansible_host=10.10.0.33 ip=10.10.0.33
worker2 ansible_host=10.10.0.3 ip=10.10.0.3

[kube_control_plane]
master1
master2
master3

[etcd:children]
kube_control_plane

[kube_node]
worker1
worker2
```

Отредактирован файл inventory/mycluster/inventory.ini

Настроены group_vars для k8s-cluster и всех узлов

```bash
cd ./kubespray
```

Проверить доступность нод:
```bash
ansible all -i inventory/mycluster/inventory.ini -m ping
```


```bash
ansible-playbook -i inventory/mycluster/inventory.ini cluster.yml
```
```
Wednesday 03 December 2025  15:19:01 +0300 (0:00:00.337)       0:22:39.895 **** 
=============================================================================== 
system_packages : Manage packages --------------------------------------------------------------------------------------------- 73.53s
download : Download_container | Download image if required -------------------------------------------------------------------- 48.12s
kubernetes/control-plane : Joining control plane node to the cluster. --------------------------------------------------------- 47.84s
container-engine/containerd : Download_file | Download item ------------------------------------------------------------------- 30.87s
container-engine/runc : Download_file | Download item ------------------------------------------------------------------------- 30.82s
container-engine/crictl : Download_file | Download item ----------------------------------------------------------------------- 30.54s
container-engine/nerdctl : Download_file | Download item ---------------------------------------------------------------------- 30.09s
etcd : Gen_certs | Write etcd member/admin and kube_control_plane client certs to other etcd nodes ---------------------------- 27.98s
kubernetes/control-plane : Control plane | wait for kube-scheduler ------------------------------------------------------------ 21.97s
container-engine/crictl : Extract_file | Unpacking archive -------------------------------------------------------------------- 19.96s
container-engine/nerdctl : Extract_file | Unpacking archive ------------------------------------------------------------------- 19.58s
download : Download_file | Download item -------------------------------------------------------------------------------------- 18.99s
kubernetes/control-plane : Kubeadm | Initialize first control plane node (1st try) -------------------------------------------- 18.83s
etcdctl_etcdutl : Download_file | Download item ------------------------------------------------------------------------------- 17.48s
download : Download_container | Download image if required -------------------------------------------------------------------- 15.94s
download : Download_container | Download image if required -------------------------------------------------------------------- 15.05s
network_plugin/calico : Start Calico resources -------------------------------------------------------------------------------- 14.42s
etcdctl_etcdutl : Extract_file | Unpacking archive ---------------------------------------------------------------------------- 12.63s
download : Download_container | Download image if required -------------------------------------------------------------------- 11.49s
download : Download_container | Download image if required -------------------------------------------------------------------- 10.09s
```

#### 2.3. Проверка результата

```bash
ansible master1 -i inventory/mycluster/inventory.ini -m command -a 'kubectl get nodes -o wide --kubeconfig /etc/kubernetes/admin.conf'
```
```
master1 | CHANGED | rc=0 >>
NAME      STATUS   ROLES           AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
master1   Ready    control-plane   14m   v1.34.2   10.10.0.35    <none>        Ubuntu 24.04.3 LTS   6.8.0-85-generic   containerd://2.1.5
master2   Ready    control-plane   14m   v1.34.2   10.10.0.27    <none>        Ubuntu 24.04.3 LTS   6.8.0-85-generic   containerd://2.1.5
master3   Ready    control-plane   13m   v1.34.2   10.10.0.25    <none>        Ubuntu 24.04.3 LTS   6.8.0-85-generic   containerd://2.1.5
worker1   Ready    <none>          12m   v1.34.2   10.10.0.33    <none>        Ubuntu 24.04.3 LTS   6.8.0-85-generic   containerd://2.1.5
worker2   Ready    <none>          12m   v1.34.2   10.10.0.3     <none>        Ubuntu 24.04.3 LTS   6.8.0-85-generic   containerd://2.1.5
```



Все необходимые манифесты, команды предоставлены и соответствуют требованиям задания.