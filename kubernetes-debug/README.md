#### 1. Запуск minikube

Запустить minikube:
```bash
minikube start
```

#### 2. Создание пода

Для создания основного контейнера пода будем использовать **kyos0109/nginx-distroless**.

Создать простанство имён **homework**:
```bash
kubectl create ns homework
```

Создать под из манифеста:
```bash
kubectl apply -f pod.yaml
```

#### 3. Запуск эфемерного контейнера для отладки пода

Для создания эфемерного контейнера будем использовать **alpine:latest**.

Создать эфемерный контейнер с доступом к пространству имён pid:
```bash
kubectl debug -n homework -it web-pod --image=alpine:latest --target=nginx --share-processes=true --profile=general
```

#### 4. Доступ к файловой системе отлаживаемого контейнера

Вывести содержимое директории /etc/nginx отлаживаемого контейнера:
```bash
ps aux | grep nginx
```
```
    1 1000      0:00 nginx: master process nginx -g daemon off;
    7 1000      0:00 nginx: worker process
   15 root      0:00 grep nginx
```

```bash
ls -la /proc/1/root/etc/nginx/
```

Получаем следующий результат:
```
total 48
drwxr-xr-x    3 root     root          4096 Oct  5  2020 .
drwxr-xr-x    1 root     root          4096 Nov 22 08:55 ..
drwxr-xr-x    2 root     root          4096 Oct  5  2020 conf.d
-rw-r--r--    1 root     root          1007 Apr 21  2020 fastcgi_params
-rw-r--r--    1 root     root          2837 Apr 21  2020 koi-utf
-rw-r--r--    1 root     root          2223 Apr 21  2020 koi-win
-rw-r--r--    1 root     root          5231 Apr 21  2020 mime.types
lrwxrwxrwx    1 root     root            22 Apr 21  2020 modules -> /usr/lib/nginx/modules
-rw-r--r--    1 root     root           643 Apr 21  2020 nginx.conf
-rw-r--r--    1 root     root           636 Apr 21  2020 scgi_params
-rw-r--r--    1 root     root           664 Apr 21  2020 uwsgi_params
-rw-r--r--    1 root     root          3610 Apr 21  2020 win-utf
```

```bash
cat /proc/1/root/etc/os-release
```
```
PRETTY_NAME="Distroless"
NAME="Debian GNU/Linux"
ID="debian"
VERSION_ID="10"
VERSION="Debian GNU/Linux 10 (buster)"
HOME_URL="https://github.com/GoogleContainerTools/distroless"
SUPPORT_URL="https://github.com/GoogleContainerTools/distroless/blob/master/README.md"
BUG_REPORT_URL="https://github.com/GoogleContainerTools/distroless/issues/new"
```

#### 5. Тестирование сети

Тестировать сеть с помощью tcpdump, что требуется в задании.

Установить tcpdump и curl:
```bash
apk add --no-cache tcpdump curl
```

Запустить tcpdump:
```bash
tcpdump -nn -i any -e port 80
```

В другом окне терминала запустить следующую команду несколько раз:
```bash
kubectl exec web-pod -n homework -c $(kubectl get po/web-pod -n homework -o jsonpath='{.spec.ephemeralContainers[0].name}') -- sh -c "curl http://localhost"
```

или запустить одновременно несколько (в данном случае три раза) команд curl http://localhost:
```bash
kubectl exec -it web-pod -c $(kubectl get po/web-pod -n homework -o jsonpath='{.spec.ephemeralContainers[0].name}') -n homework -- sh -c "seq 1 3 | xargs -n1 -P10 -I{} curl http://localhost"
```

Полученный результат tcpdump:
```
tcpdump: WARNING: any: That device doesn't support promiscuous mode
(Promiscuous mode not supported on the "any" device)
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on any, link-type LINUX_SLL2 (Linux cooked v2), snapshot length 262144 bytes
08:58:53.311559 lo    In  ifindex 1 00:00:00:00:00:00 ethertype IPv6 (0x86dd), length 100: ::1.60220 > ::1.80: Flags [S], seq 791960989, win 65476, options [mss 65476,sackOK,TS val 4283505655 ecr 0,nop,wscale 7], length 0
08:58:53.311584 lo    In  ifindex 1 00:00:00:00:00:00 ethertype IPv6 (0x86dd), length 80: ::1.80 > ::1.60220: Flags [R.], seq 0, ack 791960990, win 0, length 0
08:58:53.311942 lo    In  ifindex 1 00:00:00:00:00:00 ethertype IPv4 (0x0800), length 80: 127.0.0.1.56558 > 127.0.0.1.80: Flags [S], seq 1981857603, win 65495, options [mss 65495,sackOK,TS val 3353776680 ecr 0,nop,wscale 7], length 0
08:58:53.311960 lo    In  ifindex 1 00:00:00:00:00:00 ethertype IPv4 (0x0800), length 80: 127.0.0.1.80 > 127.0.0.1.56558: Flags [S.], seq 2462079018, ack 1981857604, win 65483, options [mss 65495,sackOK,TS val 3353776680 ecr 3353776680,nop,wscale 7], length 0
08:58:53.311975 lo    In  ifindex 1 00:00:00:00:00:00 ethertype IPv4 (0x0800), length 72: 127.0.0.1.56558 > 127.0.0.1.80: Flags [.], ack 1, win 512, options [nop,nop,TS val 3353776680 ecr 3353776680], length 0
08:58:53.312549 lo    In  ifindex 1 00:00:00:00:00:00 ethertype IPv4 (0x0800), length 145: 127.0.0.1.56558 > 127.0.0.1.80: Flags [P.], seq 1:74, ack 1, win 512, options [nop,nop,TS val 3353776681 ecr 3353776680], length 73: HTTP: GET / HTTP/1.1
08:58:53.312558 lo    In  ifindex 1 00:00:00:00:00:00 ethertype IPv4 (0x0800), length 72: 127.0.0.1.80 > 127.0.0.1.56558: Flags [.], ack 74, win 512, options [nop,nop,TS val 3353776681 ecr 3353776681], length 0
08:58:53.313026 lo    In  ifindex 1 00:00:00:00:00:00 ethertype IPv4 (0x0800), length 310: 127.0.0.1.80 > 127.0.0.1.56558: Flags [P.], seq 1:239, ack 74, win 512, options [nop,nop,TS val 3353776681 ecr 3353776681], length 238: HTTP: HTTP/1.1 200 OK
08:58:53.313051 lo    In  ifindex 1 00:00:00:00:00:00 ethertype IPv4 (0x0800), length 72: 127.0.0.1.56558 > 127.0.0.1.80: Flags [.], ack 239, win 511, options [nop,nop,TS val 3353776681 ecr 3353776681], length 0
08:58:53.313222 lo    In  ifindex 1 00:00:00:00:00:00 ethertype IPv4 (0x0800), length 684: 127.0.0.1.80 > 127.0.0.1.56558: Flags [P.], seq 239:851, ack 74, win 512, options [nop,nop,TS val 3353776682 ecr 3353776681], length 612: HTTP
08:58:53.313235 lo    In  ifindex 1 00:00:00:00:00:00 ethertype IPv4 (0x0800), length 72: 127.0.0.1.56558 > 127.0.0.1.80: Flags [.], ack 851, win 507, options [nop,nop,TS val 3353776682 ecr 3353776682], length 0
08:58:53.313519 lo    In  ifindex 1 00:00:00:00:00:00 ethertype IPv4 (0x0800), length 72: 127.0.0.1.56558 > 127.0.0.1.80: Flags [F.], seq 74, ack 851, win 507, options [nop,nop,TS val 3353776682 ecr 3353776682], length 0
08:58:53.313742 lo    In  ifindex 1 00:00:00:00:00:00 ethertype IPv4 (0x0800), length 72: 127.0.0.1.80 > 127.0.0.1.56558: Flags [F.], seq 851, ack 75, win 512, options [nop,nop,TS val 3353776682 ecr 3353776682], length 0
08:58:53.313777 lo    In  ifindex 1 00:00:00:00:00:00 ethertype IPv4 (0x0800), length 72: 127.0.0.1.56558 > 127.0.0.1.80: Flags [.], ack 852, win 507, options [nop,nop,TS val 3353776682 ecr 3353776682], length 0
08:58:56.221880 lo    In  ifindex 1 00:00:00:00:00:00 ethertype IPv6 (0x86dd), length 100: ::1.58270 > ::1.80: Flags [S], seq 3057399949, win 65476, options [mss 65476,sackOK,TS val 4283508565 ecr 0,nop,wscale 7], length 0
08:58:56.221887 lo    In  ifindex 1 00:00:00:00:00:00 ethertype IPv6 (0x86dd), length 80: ::1.80 > ::1.58270: Flags [R.], seq 0, ack 3057399950, win 0, length 0
08:58:56.221981 lo    In  ifindex 1 00:00:00:00:00:00 ethertype IPv4 (0x0800), length 80: 127.0.0.1.34684 > 127.0.0.1.80: Flags [S], seq 10096552, win 65495, options [mss 65495,sackOK,TS val 3353779590 ecr 0,nop,wscale 7], length 0
08:58:56.222008 lo    In  ifindex 1 00:00:00:00:00:00 ethertype IPv4 (0x0800), length 80: 127.0.0.1.80 > 127.0.0.1.34684: Flags [S.], seq 1618096362, ack 10096553, win 65483, options [mss 65495,sackOK,TS val 3353779590 ecr 3353779590,nop,wscale 7], length 0
08:58:56.222022 lo    In  ifindex 1 00:00:00:00:00:00 ethertype IPv4 (0x0800), length 72: 127.0.0.1.34684 > 127.0.0.1.80: Flags [.], ack 1, win 512, options [nop,nop,TS val 3353779590 ecr 3353779590], length 0
08:58:56.222709 lo    In  ifindex 1 00:00:00:00:00:00 ethertype IPv4 (0x0800), length 145: 127.0.0.1.34684 > 127.0.0.1.80: Flags [P.], seq 1:74, ack 1, win 512, options [nop,nop,TS val 3353779591 ecr 3353779590], length 73: HTTP: GET / HTTP/1.1
08:58:56.222726 lo    In  ifindex 1 00:00:00:00:00:00 ethertype IPv4 (0x0800), length 72: 127.0.0.1.80 > 127.0.0.1.34684: Flags [.], ack 74, win 512, options [nop,nop,TS val 3353779591 ecr 3353779591], length 0
08:58:56.222901 lo    In  ifindex 1 00:00:00:00:00:00 ethertype IPv4 (0x0800), length 310: 127.0.0.1.80 > 127.0.0.1.34684: Flags [P.], seq 1:239, ack 74, win 512, options [nop,nop,TS val 3353779591 ecr 3353779591], length 238: HTTP: HTTP/1.1 200 OK
08:58:56.222916 lo    In  ifindex 1 00:00:00:00:00:00 ethertype IPv4 (0x0800), length 72: 127.0.0.1.34684 > 127.0.0.1.80: Flags [.], ack 239, win 511, options [nop,nop,TS val 3353779591 ecr 3353779591], length 0
08:58:56.222954 lo    In  ifindex 1 00:00:00:00:00:00 ethertype IPv4 (0x0800), length 684: 127.0.0.1.80 > 127.0.0.1.34684: Flags [P.], seq 239:851, ack 74, win 512, options [nop,nop,TS val 3353779591 ecr 3353779591], length 612: HTTP
08:58:56.222962 lo    In  ifindex 1 00:00:00:00:00:00 ethertype IPv4 (0x0800), length 72: 127.0.0.1.34684 > 127.0.0.1.80: Flags [.], ack 851, win 507, options [nop,nop,TS val 3353779591 ecr 3353779591], length 0
08:58:56.223859 lo    In  ifindex 1 00:00:00:00:00:00 ethertype IPv4 (0x0800), length 72: 127.0.0.1.34684 > 127.0.0.1.80: Flags [F.], seq 74, ack 851, win 507, options [nop,nop,TS val 3353779592 ecr 3353779591], length 0
08:58:56.224311 lo    In  ifindex 1 00:00:00:00:00:00 ethertype IPv4 (0x0800), length 72: 127.0.0.1.80 > 127.0.0.1.34684: Flags [F.], seq 851, ack 75, win 512, options [nop,nop,TS val 3353779593 ecr 3353779592], length 0
08:58:56.224348 lo    In  ifindex 1 00:00:00:00:00:00 ethertype IPv4 (0x0800), length 72: 127.0.0.1.34684 > 127.0.0.1.80: Flags [.], ack 852, win 507, options [nop,nop,TS val 3353779593 ecr 3353779593], length 0
08:58:58.406539 lo    In  ifindex 1 00:00:00:00:00:00 ethertype IPv6 (0x86dd), length 100: ::1.58272 > ::1.80: Flags [S], seq 2974444382, win 65476, options [mss 65476,sackOK,TS val 4283510750 ecr 0,nop,wscale 7], length 0
08:58:58.406561 lo    In  ifindex 1 00:00:00:00:00:00 ethertype IPv6 (0x86dd), length 80: ::1.80 > ::1.58272: Flags [R.], seq 0, ack 2974444383, win 0, length 0
08:58:58.406788 lo    In  ifindex 1 00:00:00:00:00:00 ethertype IPv4 (0x0800), length 80: 127.0.0.1.34698 > 127.0.0.1.80: Flags [S], seq 2820232141, win 65495, options [mss 65495,sackOK,TS val 3353781775 ecr 0,nop,wscale 7], length 0
08:58:58.406823 lo    In  ifindex 1 00:00:00:00:00:00 ethertype IPv4 (0x0800), length 80: 127.0.0.1.80 > 127.0.0.1.34698: Flags [S.], seq 2663399670, ack 2820232142, win 65483, options [mss 65495,sackOK,TS val 3353781775 ecr 3353781775,nop,wscale 7], length 0
08:58:58.406858 lo    In  ifindex 1 00:00:00:00:00:00 ethertype IPv4 (0x0800), length 72: 127.0.0.1.34698 > 127.0.0.1.80: Flags [.], ack 1, win 512, options [nop,nop,TS val 3353781775 ecr 3353781775], length 0
08:58:58.407198 lo    In  ifindex 1 00:00:00:00:00:00 ethertype IPv4 (0x0800), length 145: 127.0.0.1.34698 > 127.0.0.1.80: Flags [P.], seq 1:74, ack 1, win 512, options [nop,nop,TS val 3353781775 ecr 3353781775], length 73: HTTP: GET / HTTP/1.1
08:58:58.407232 lo    In  ifindex 1 00:00:00:00:00:00 ethertype IPv4 (0x0800), length 72: 127.0.0.1.80 > 127.0.0.1.34698: Flags [.], ack 74, win 512, options [nop,nop,TS val 3353781776 ecr 3353781775], length 0
08:58:58.407461 lo    In  ifindex 1 00:00:00:00:00:00 ethertype IPv4 (0x0800), length 310: 127.0.0.1.80 > 127.0.0.1.34698: Flags [P.], seq 1:239, ack 74, win 512, options [nop,nop,TS val 3353781776 ecr 3353781775], length 238: HTTP: HTTP/1.1 200 OK
08:58:58.407689 lo    In  ifindex 1 00:00:00:00:00:00 ethertype IPv4 (0x0800), length 72: 127.0.0.1.34698 > 127.0.0.1.80: Flags [.], ack 239, win 511, options [nop,nop,TS val 3353781776 ecr 3353781776], length 0
08:58:58.407707 lo    In  ifindex 1 00:00:00:00:00:00 ethertype IPv4 (0x0800), length 684: 127.0.0.1.80 > 127.0.0.1.34698: Flags [P.], seq 239:851, ack 74, win 512, options [nop,nop,TS val 3353781776 ecr 3353781776], length 612: HTTP
08:58:58.407717 lo    In  ifindex 1 00:00:00:00:00:00 ethertype IPv4 (0x0800), length 72: 127.0.0.1.34698 > 127.0.0.1.80: Flags [.], ack 851, win 507, options [nop,nop,TS val 3353781776 ecr 3353781776], length 0
08:58:58.408266 lo    In  ifindex 1 00:00:00:00:00:00 ethertype IPv4 (0x0800), length 72: 127.0.0.1.34698 > 127.0.0.1.80: Flags [F.], seq 74, ack 851, win 507, options [nop,nop,TS val 3353781777 ecr 3353781776], length 0
08:58:58.409021 lo    In  ifindex 1 00:00:00:00:00:00 ethertype IPv4 (0x0800), length 72: 127.0.0.1.80 > 127.0.0.1.34698: Flags [F.], seq 851, ack 75, win 512, options [nop,nop,TS val 3353781777 ecr 3353781777], length 0
08:58:58.409073 lo    In  ifindex 1 00:00:00:00:00:00 ethertype IPv4 (0x0800), length 72: 127.0.0.1.34698 > 127.0.0.1.80: Flags [.], ack 852, win 507, options [nop,nop,TS val 3353781777 ecr 3353781777], length 0
^C
42 packets captured
84 packets received by filter
0 packets dropped by kernel
```

#### 6. Выполнение strace для корневого процесса nginx в поде

Установить starce:
```bash
apk add --no-cache strace
```

Найти PID nginx:
```bash
ps aux | grep nginx
```
```
    1 1000      0:00 nginx: master process nginx -g daemon off;
    7 1000      0:00 nginx: worker process
```

Выполнить strace:
```bash
strace -p 1 -f
```

В другом окне терминала запустить команду, например, перезагрузки конфигурации nginx:
```bash
kubectl exec -it web-pod -c $(kubectl get po/web-pod -n homework -o jsonpath='{.spec.ephemeralContainers[0].name}') -n homework -- kill -HUP 1
```

Полученный результат выполнения strace:
```
strace: Process 1 attached
rt_sigsuspend([], 8)                    = ? ERESTARTNOHAND (To be restarted if no handler)
--- SIGHUP {si_signo=SIGHUP, si_code=SI_USER, si_pid=49, si_uid=0} ---
rt_sigreturn({mask=[HUP INT QUIT USR1 USR2 ALRM TERM CHLD WINCH IO]}) = -1 EINTR (Interrupted system call)
stat("/etc/localtime", {st_mode=S_IFREG|0644, st_size=790, ...}) = 0
uname({sysname="Linux", nodename="web-pod", ...}) = 0
openat(AT_FDCWD, "/etc/nginx/nginx.conf", O_RDONLY) = 8
fstat(8, {st_mode=S_IFREG|0644, st_size=643, ...}) = 0
pread64(8, "\nuser  nginx;\nworker_processes  "..., 643, 0) = 643
geteuid()                               = 1000
gettid()                                = 1
write(4, "2025/11/22 17:01:53 [warn] 1#1: "..., 160) = 160
epoll_create(100)                       = 9
close(9)                                = 0
openat(AT_FDCWD, "/etc/nginx/mime.types", O_RDONLY) = 9
fstat(9, {st_mode=S_IFREG|0644, st_size=5231, ...}) = 0
pread64(9, "\ntypes {\n    text/html          "..., 4096, 0) = 4096
pread64(9, "pplication/octet-stream         "..., 1135, 4096) = 1135
close(9)                                = 0
openat(AT_FDCWD, "/etc/nginx/conf.d", O_RDONLY|O_NONBLOCK|O_CLOEXEC|O_DIRECTORY) = 9
fstat(9, {st_mode=S_IFDIR|0755, st_size=4096, ...}) = 0
brk(0x5f9dcd390000)                     = 0x5f9dcd390000
getdents64(9, 0x5f9dcd3674f0 /* 3 entries */, 32768) = 80
getdents64(9, 0x5f9dcd3674f0 /* 0 entries */, 32768) = 0
brk(0x5f9dcd388000)                     = 0x5f9dcd388000
close(9)                                = 0
openat(AT_FDCWD, "/etc/nginx/conf.d/default.conf", O_RDONLY) = 9
fstat(9, {st_mode=S_IFREG|0644, st_size=1093, ...}) = 0
pread64(9, "server {\n    listen       80;\n  "..., 1093, 0) = 1093
close(9)                                = 0
close(8)                                = 0
geteuid()                               = 1000
mkdir("/var/cache/nginx/client_temp", 0700) = -1 EEXIST (File exists)
mkdir("/var/cache/nginx/proxy_temp", 0700) = -1 EEXIST (File exists)
mkdir("/var/cache/nginx/fastcgi_temp", 0700) = -1 EEXIST (File exists)
mkdir("/var/cache/nginx/uwsgi_temp", 0700) = -1 EEXIST (File exists)
mkdir("/var/cache/nginx/scgi_temp", 0700) = -1 EEXIST (File exists)
openat(AT_FDCWD, "/var/log/nginx/error.log", O_WRONLY|O_CREAT|O_APPEND, 0644) = 8
fcntl(8, F_SETFD, FD_CLOEXEC)           = 0
openat(AT_FDCWD, "/var/log/nginx/access.log", O_WRONLY|O_CREAT|O_APPEND, 0644) = 9
fcntl(9, F_SETFD, FD_CLOEXEC)           = 0
dup2(8, 2)                              = 2
prlimit64(0, RLIMIT_NOFILE, NULL, {rlim_cur=1024*1024, rlim_max=1024*1024}) = 0
close(4)                                = 0
close(5)                                = 0
socketpair(AF_UNIX, SOCK_STREAM, 0, [4, 5]) = 0
ioctl(4, FIONBIO, [1])                  = 0
ioctl(5, FIONBIO, [1])                  = 0
ioctl(4, FIOASYNC, [1])                 = 0
fcntl(4, F_SETOWN, 1)                   = 0
fcntl(4, F_SETFD, FD_CLOEXEC)           = 0
fcntl(5, F_SETFD, FD_CLOEXEC)           = 0
clone(child_stack=NULL, flags=CLONE_CHILD_CLEARTID|CLONE_CHILD_SETTID|SIGCHLDstrace: Process 55 attached
, child_tidptr=0x79a4a2ecce50) = 55
[pid    55] set_robust_list(0x79a4a2ecce60, 24 <unfinished ...>
[pid     1] sendmsg(3, {msg_name=NULL, msg_namelen=0, msg_iov=[{iov_base="\1\0\0\0\0\0\0\0007\0\0\0\0\0\0\0\1\0\0\0\0\0\0\0\4\0\0\0\0\0\0\0", iov_len=32}], msg_iovlen=1, msg_control=[{cmsg_len=20, cmsg_level=SOL_SOCKET, cmsg_type=SCM_RIGHTS, cmsg_data=[4]}], msg_controllen=24, msg_flags=0}, 0 <unfinished ...>
[pid    55] <... set_robust_list resumed>) = 0
[pid     1] <... sendmsg resumed>)      = 32
[pid    55] getpid( <unfinished ...>
[pid     1] nanosleep({tv_sec=0, tv_nsec=100000000},  <unfinished ...>
[pid    55] <... getpid resumed>)       = 55
[pid    55] geteuid()                   = 1000
[pid    55] prctl(PR_SET_DUMPABLE, SUID_DUMP_USER) = 0
[pid    55] rt_sigprocmask(SIG_SETMASK, [], NULL, 8) = 0
[pid    55] epoll_create(512)           = 10
[pid    55] eventfd2(0, 0)              = 11
[pid    55] epoll_ctl(10, EPOLL_CTL_ADD, 11, {events=EPOLLIN|EPOLLET, data=0x5f9dc8f3d4a0}) = 0
[pid    55] eventfd2(0, 0)              = 12
[pid    55] ioctl(12, FIONBIO, [1])     = 0
[pid    55] io_setup(32, [0x79a4a2eca000]) = 0
[pid    55] epoll_ctl(10, EPOLL_CTL_ADD, 12, {events=EPOLLIN|EPOLLET, data=0x5f9dc8f3d340}) = 0
[pid    55] socketpair(AF_UNIX, SOCK_STREAM, 0, [13, 14]) = 0
[pid    55] epoll_ctl(10, EPOLL_CTL_ADD, 13, {events=EPOLLIN|EPOLLRDHUP|EPOLLET, data=0x5f9dc8f3d340}) = 0
[pid    55] close(14)                   = 0
[pid    55] epoll_wait(10, [{events=EPOLLIN|EPOLLHUP|EPOLLRDHUP, data=0x5f9dc8f3d340}], 1, 5000) = 1
[pid    55] close(13)                   = 0
[pid    55] mmap(NULL, 241664, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0) = 0x79a4a2e8f000
[pid    55] brk(0x5f9dcd3ae000)         = 0x5f9dcd3ae000
[pid    55] epoll_ctl(10, EPOLL_CTL_ADD, 6, {events=EPOLLIN|EPOLLRDHUP, data=0x79a4a2e8f010}) = 0
[pid    55] close(7)                    = 0
[pid    55] close(4)                    = 0
[pid    55] epoll_ctl(10, EPOLL_CTL_ADD, 5, {events=EPOLLIN|EPOLLRDHUP, data=0x79a4a2e8f0f8}) = 0
[pid    55] epoll_wait(10,  <unfinished ...>
[pid     1] <... nanosleep resumed>NULL) = 0
[pid     1] sendmsg(3, {msg_name=NULL, msg_namelen=0, msg_iov=[{iov_base="\3\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\377\377\377\377\0\0\0\0", iov_len=32}], msg_iovlen=1, msg_controllen=0, msg_flags=0}, 0) = 32
[pid     1] rt_sigsuspend([], 8)        = ? ERESTARTNOHAND (To be restarted if no handler)
[pid     1] --- SIGCHLD {si_signo=SIGCHLD, si_code=CLD_EXITED, si_pid=7, si_uid=1000, si_status=0, si_utime=0, si_stime=0} ---
[pid     1] wait4(-1, [{WIFEXITED(s) && WEXITSTATUS(s) == 0}], WNOHANG, NULL) = 7
[pid     1] wait4(-1, 0x7ffc9aeb8034, WNOHANG, NULL) = 0
[pid     1] rt_sigreturn({mask=[HUP INT QUIT USR1 USR2 ALRM TERM CHLD WINCH IO]}) = -1 EINTR (Interrupted system call)
[pid     1] close(3)                    = 0
[pid     1] close(7)                    = 0
[pid     1] sendmsg(4, {msg_name=NULL, msg_namelen=0, msg_iov=[{iov_base="\2\0\0\0\0\0\0\0\7\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\377\377\377\377\0\0\0\0", iov_len=32}], msg_iovlen=1, msg_controllen=0, msg_flags=0}, 0) = 32
[pid    55] <... epoll_wait resumed>[{events=EPOLLIN, data=0x79a4a2e8f0f8}], 512, -1) = 1
[pid     1] rt_sigsuspend([], 8 <unfinished ...>
[pid    55] recvmsg(5,  <unfinished ...>
[pid     1] <... rt_sigsuspend resumed>) = ? ERESTARTNOHAND (To be restarted if no handler)
[pid    55] <... recvmsg resumed>{msg_name=NULL, msg_namelen=0, msg_iov=[{iov_base="\2\0\0\0\0\0\0\0\7\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\377\377\377\377\0\0\0\0", iov_len=32}], msg_iovlen=1, msg_controllen=0, msg_flags=0}, 0) = 32
[pid     1] --- SIGIO {si_signo=SIGIO, si_code=SI_KERNEL} ---
[pid    55] close(3 <unfinished ...>
[pid     1] rt_sigreturn({mask=[HUP INT QUIT USR1 USR2 ALRM TERM CHLD WINCH IO]} <unfinished ...>
[pid    55] <... close resumed>)        = 0
[pid     1] <... rt_sigreturn resumed>) = -1 EINTR (Interrupted system call)
[pid    55] recvmsg(5,  <unfinished ...>
[pid     1] rt_sigsuspend([], 8 <unfinished ...>
[pid    55] <... recvmsg resumed>{msg_namelen=0}, 0) = -1 EAGAIN (Resource temporarily unavailable)
[pid    55] epoll_wait(10, ^Cstrace: Process 55 detached
 <detached ...>
strace: Process 1 detached
```

#### 7. Доступ к файловой системе и логам ноды

Запустить отладочный под для ноды, на которой запущен под с distroless nginx:
```bash
kubectl debug node/minikube -it --image=alpine:latest --profile=general
```

Получить доступ к файловой системе ноды:
```bash
chroot /host
```

Получить логи пода с distrolles nginx:

```bash
cat /var/log/pods/homework_web-pod_*/nginx/0.log
```

Получаем результат:
```
{"log":"2025/11/22 16:55:14 [warn] 1#1: the \"user\" directive makes sense only if the master process runs with super-user privileges, ignored in /etc/nginx/nginx.conf:2\n","stream":"stderr","time":"2025-11-22T08:55:14.311841347Z"}
{"log":"nginx: [warn] the \"user\" directive makes sense only if the master process runs with super-user privileges, ignored in /etc/nginx/nginx.conf:2\n","stream":"stderr","time":"2025-11-22T08:55:14.311952544Z"}
{"log":"127.0.0.1 - - [22/Nov/2025:16:58:53 +0800] \"GET / HTTP/1.1\" 200 612 \"-\" \"curl/8.14.1\" \"-\"\n","stream":"stdout","time":"2025-11-22T08:58:53.314545804Z"}
{"log":"127.0.0.1 - - [22/Nov/2025:16:58:56 +0800] \"GET / HTTP/1.1\" 200 612 \"-\" \"curl/8.14.1\" \"-\"\n","stream":"stdout","time":"2025-11-22T08:58:56.2244862Z"}
{"log":"127.0.0.1 - - [22/Nov/2025:16:58:58 +0800] \"GET / HTTP/1.1\" 200 612 \"-\" \"curl/8.14.1\" \"-\"\n","stream":"stdout","time":"2025-11-22T08:58:58.408096213Z"}
{"log":"2025/11/22 17:01:53 [warn] 1#1: the \"user\" directive makes sense only if the master process runs with super-user privileges, ignored in /etc/nginx/nginx.conf:2\n","stream":"stderr","time":"2025-11-22T09:01:53.06282165Z"}
```


Все задачи успешно выполнены, включая отладку с помощью эфемерных контейнеров, анализ сети через tcpdump, доступ к логам на уровне ноды и трассировку системных вызовов процесса nginx.