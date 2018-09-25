# 利用docker仓库自动构建功能获得　kubernetes 容器
>利用镜像源的地址拉取镜像，并且构建

## kubernetes 二进制源
* [阿里云](https://opsx.alibaba.com/mirror)
* [中国科技大学](http://mirrors.ustc.edu.cn/)


## docker k8s 镜像
``` 
https://hub.docker.com/u/jingjingxyk/
```

## centos7 kubernetes 环境准备

### 关闭交换分区
```shell 

#禁用交换分区
vi  /etc/fstab 
#注释 swap 行
swapoff -a
 
```

### 关闭防火墙
```shell 
systemctl stop firewalld
systemctl disable firewalld
```

### 安装docker软件
```shell 
curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
systemctl enable docker.service
systemctl start docker.service
＃docker 仓库中国区加速
vi /etc/docker/daemon.json 
{ 
   "registry-mirrors": ["https://registry.docker-cn.com"] 
}

```

### linux 添加内核添加　br_netfilter和配置
```shell 

modprobe br_netfilter
vi /etc/sysctl.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
sysctl -p

```

### 安装kubernetes
```shell
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

setenforce 0

yum install -y kubelet kubeadm kubectl
systemctl enable kubelet && systemctl start kubelet


```


### 准备kubernetes docker镜像   v1.11.2版本　
>> 查询需要哪一些镜像，使用如下命令
```shell 
kubeadm config images list  --kubernetes-version=1.11.2
```
```shell 

k8s.gcr.io/kube-apiserver-amd64:v1.11.2
k8s.gcr.io/kube-controller-manager-amd64:v1.11.2
k8s.gcr.io/kube-scheduler-amd64:v1.11.2
k8s.gcr.io/kube-proxy-amd64:v1.11.2
k8s.gcr.io/pause:3.1
k8s.gcr.io/etcd-amd64:3.2.18
k8s.gcr.io/coredns:1.1.3

```
#### master　节点所需镜像　（在master节点上操作）
```shell 
docker pull jingjingxyk/dockerfile-k8s:etcd
docker tag jingjingxyk/dockerfile-k8s:etcd k8s.gcr.io/etcd-amd64:3.2.18

docker pull jingjingxyk/dockerfile-k8s:kube-apiserver
docker tag jingjingxyk/dockerfile-k8s:kube-apiserver k8s.gcr.io/kube-apiserver-amd64:v1.11.2

docker pull jingjingxyk/dockerfile-k8s:kube-controller-manager
docker tag jingjingxyk/dockerfile-k8s:kube-controller-manager k8s.gcr.io/kube-controller-manager-amd64:v1.11.2

docker pull jingjingxyk/dockerfile-k8s:kube-proxy
docker tag jingjingxyk/dockerfile-k8s:kube-proxy k8s.gcr.io/kube-proxy-amd64:v1.11.2

docker pull jingjingxyk/dockerfile-k8s:kube-scheduler
docker tag jingjingxyk/dockerfile-k8s:kube-scheduler k8s.gcr.io/kube-scheduler-amd64:v1.11.2

docker pull jingjingxyk/dockerfile-k8s:pause
docker tag jingjingxyk/dockerfile-k8s:pause k8s.gcr.io/pause:3.1

docker pull jingjingxyk/dockerfile-k8s:coredns
docker tag jingjingxyk/dockerfile-k8s:coredns k8s.gcr.io/coredns:1.1.3

docker pull jingjingxyk/dockerfile-flannel:flannel
docker tag jingjingxyk/dockerfile-flannel:flannel quay.io/coreos/flannel:v0.10.0-amd64

docker pull jingjingxyk/dockerfile-k8s:kubernetes-dashboard
docker tag jingjingxyk/dockerfile-k8s:kubernetes-dashboard k8s.gcr.io/kubernetes-dashboard-amd64:v1.10.0



#清理多余的镜像
docker rmi $(docker images |grep 'jingjingxyk/dockerfile-k8s' |awk '{print $1":"$2}')
docker rmi $(docker images |grep 'jingjingxyk/dockerfile-flannel' |awk '{print $1":"$2}')


```

#### slave节点所需docker镜像　(在节点上操作)
```shell 
docker pull jingjingxyk/dockerfile-k8s:kube-proxy
docker tag jingjingxyk/dockerfile-k8s:kube-proxy k8s.gcr.io/kube-proxy-amd64:v1.11.2

docker pull jingjingxyk/dockerfile-k8s:pause
docker tag jingjingxyk/dockerfile-k8s:pause k8s.gcr.io/pause:3.1


docker pull jingjingxyk/dockerfile-flannel:flannel
docker tag jingjingxyk/dockerfile-flannel:flannel quay.io/coreos/flannel:v0.10.0-amd64


#清理多余的镜像
docker rmi $(docker images |grep 'jingjingxyk/dockerfile-k8s' |awk '{print $1":"$2}')
docker rmi $(docker images |grep 'jingjingxyk/dockerfile-flannel' |awk '{print $1":"$2}')


```

#### master节点上　初始化kubernetes集群
>apiserver-advertise-address 根据实际情况指定ip地址
```shell
kubeadm init --kubernetes-version=1.11.2 --pod-network-cidr=10.244.0.0/16  --token-ttl 0  --apiserver-advertise-address=192.168.1.21
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config

 #slave　节点加入执行命令
 kubeadm join 192.168.1.21:6443 --token ad4q0l.j7aprpvfo0ejcbpr --discovery-token-ca-cert-hash sha256:b7762f563975c8852dd48d77c9f140598716696ea7e9af55d576bf7e56bf95ae
```
[创建kubernetes集群参考](https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/)

#### master节点上配置网络组件 flannel 
```shell 
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/v0.10.0/Documentation/kube-flannel.yml
```
>kube-dns 在k8s-v1.10 以后被coredns取代
>可用的网路组件不止flannel　还有很多，查看地址

[更多pod网络组件](https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/#pod-network)

#### slave节点上执行
>>先准备必要的K8s镜像
```shell 
 kubeadm join 192.168.1.21:6443 --token ad4q0l.j7aprpvfo0ejcbpr --discovery-token-ca-cert-hash sha256:b7762f563975c8852dd48d77c9f140598716696ea7e9af55d576bf7e56bf95ae

```


## 如果已经忘记了加入节点的token 和签名执行如下操作
```shell 
    kubeamd token list
    openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | \
    openssl dgst -sha256 -hex | sed 's/^.* //'
```

## master节点也能部署用户pod　执行一下命令
>默认master节点不能安装用户pod
```shell 

kubectl taint nodes --all node-role.kubernetes.io/master-
```


## 安装集群　web-ui-dashboard　
[web-ui-dashboard参考说明](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/)
```shell 
kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml

# kubernetes-dashboard-remote-access 
vi kubernetes-dashboard-ui-rbac.yaml
    apiVersion: rbac.authorization.k8s.io/v1beta1
    kind: ClusterRoleBinding
    metadata:
      name: kubernetes-dashboard
      labels:
        k8s-app: kubernetes-dashboard
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      name: cluster-admin
    subjects:
    - kind: ServiceAccount
      name: kubernetes-dashboard
      namespace: kube-system
  
 
kubeclt create -f kubernetes-dashboard-ui-rbac.yaml

```
[kubernetes-dashboard-remote-access](https://blog.tekspace.io/kubernetes-dashboard-remote-access/)


## 主节点执行此命令　
```shell 
kubectl proxy　
```

## ssh代理转发
> 客户端执行
```shell 
ssh -CNg -L 8001:127.0.0.1:8001  root@192.168.1.21 -i ./identify.pem

```




## 浏览器打开如下地址
> 浏览器打开如下地址，就能看到　kubernetes-dashboard-ui
```
http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/

```

## master节点获取访问令牌
```
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep kubernetes-dashboard| awk '{print $1}')
        
```

## ingress ingress-controller安装 
* [ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
* [ingress-nginx-controller]( https://kubernetes.github.io/ingress-nginx/deploy/#generic-deployment)
* [ingress-nginx-deploy](https://github.com/kubernetes/ingress-nginx/tree/master/deploy)
 
 
```
#指定slave节点执行如下命令获取　Ingree　安装环境
docker pull jingjingxyk/dockerfile-k8s:defaultbackend
docker tag jingjingxyk/dockerfile-k8s:defaultbackend gcr.io/google_containers/defaultbackend:1.4

docker pull jingjingxyk/dockerfile-k8s:kubernetes-ingress-controller
docker tag jingjingxyk/dockerfile-k8s:kubernetes-ingress-controller quay.io/kubernetes-ingress-controller/nginx-ingress-controller:0.19.0


```
```shell 
#主节点执行
curl -o ingress-nginx-deploy-mandatory.yaml https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/mandatory.yaml

```

## pod指定安装节点　比如ingress－controller需要指定安装节点　
```shell
#给节点打标签
kubectl label nodes k8s-node-1 ingress-controller-position=k8s-node-1

```
> 修改ingress-nginxr配置文件　ingress-nginx－deploy－mandatory.yaml　

```yaml 

spec:
  nodeSelector:
    ingress-controller-position: "k8s-node-1"　＃配置节点
  containers:
    - name: nginx-ingress-controller
      image: quay.io/kubernetes-ingress-controller/nginx-ingress-controller:0.19.0
    

```
 ```shell 
 #kubeclt create -f ingress-nginx－deploy－mandatory.yaml　
 ```
    

## 查看所有pod
```shell 

 kubectl get pods --all-namespaces -o wide 
 kubectl get svc --all-namespaces -o wide
 kubectl get ingress 
 
 #查看那错误
 journalctl -xeu kubelet
 
```

#### 多个节点之间共享卷　使用pv和pvc实现,文件系统
> glusterfs  hostPath nfs flocker cephfs

* [volumes](https://github.com/kubernetes/examples/tree/master/staging/volumes)     
* [persistent-volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)   
* [cephfs](https://kubernetes.io/docs/concepts/storage/volumes/#cephfs)    
* [nfs](https://www.howtoforge.com/nfs-server-and-client-on-centos-7)  



## k8s 集群安装好以后　配置一个项目例子
> example　目录下
[配置项目集群例子](examples/)



## 组件仓库地址
```
https://hub.docker.com/u/jingjingxyk/

https://github.com/jingjingxyk/dockerfile-calico
https://github.com/jingjingxyk/dockerfile-canal
https://github.com/jingjingxyk/Dockerfile-flannel

```


## 镜像源参考
　1. [镜像源](https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-init/#running-kubeadm-without-an-internet-connection)
　2. [没有网络连接的情况下镜像源版本](https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-init/#running-kubeadm-without-an-internet-connection)　 

 
 ## google_containers  镜像构建参考
 1. [安装kubernetes，访问不了gcr.io怎么办？](https://www.colabug.com/863347.html)
 2. [使用kubeadm部署k8s集群00-缓存gcr.io镜像](http://blog.51cto.com/nosmoking/2069950?utm_source=oschina-app)
 3. [Google Container Registry(gcr.io) 中国可用镜像(长期维护)](https://anjia0532.github.io/2017/11/15/gcr-io-image-mirror/)
 4. [gcr.io_mirror](https://github.com/anjia0532/gcr.io_mirror/tree/master/google-samples)
