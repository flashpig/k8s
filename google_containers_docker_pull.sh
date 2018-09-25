#!/usr/bin/env bash
#版本参考地址
#https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-init/#running-kubeadm-without-an-internet-connection
#docker　
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


docker pull jingjingxyk/dockerfile-k8s:defaultbackend
docker tag jingjingxyk/dockerfile-k8s:defaultbackend gcr.io/google_containers/defaultbackend:1.4

docker pull jingjingxyk/dockerfile-k8s:kubernetes-ingress-controller
docker tag jingjingxyk/dockerfile-k8s:kubernetes-ingress-controller quay.io/kubernetes-ingress-controller/nginx-ingress-controller:0.19.0

docker pull jingjingxyk/dockerfile-k8s:kubernetes-dashboard
docker tag jingjingxyk/dockerfile-k8s:kubernetes-dashboard k8s.gcr.io/kubernetes-dashboard-amd64:v1.10.0



docker pull jingjingxyk/dockerfile-k8s:volume-nfs
docker tag  jingjingxyk/dockerfile-k8s:volume-nfs gcr.io/google_containers/volume-nfs

docker pull jingjingxyk/dockerfile-k8s:external-storage-cephfs
docker tag  jingjingxyk/dockerfile-k8s:external-storage-cephfs quay.io/external_storage/cephfs-provisioner:latest

docker pull jingjingxyk/dockerfile-k8s:external-storage-nfs
docker tag  jingjingxyk/dockerfile-k8s:external-storage-nfs  quay.io/kubernetes_incubator/nfs-provisioner:latest



#coredns 需要　network addons　 https://kubernetes.io/docs/concepts/cluster-administration/addons/
#v1.11.1 以后　coredns　取代　kube-dns(可以不要了)


#清理多余的镜像
docker rmi $(docker images |grep 'jingjingxyk/dockerfile-k8s' |awk '{print $1":"$2}')
docker rmi $(docker images |grep 'jingjingxyk/dockerfile-flannel' |awk '{print $1":"$2}')


