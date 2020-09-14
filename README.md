
第一次部署

```
- 进入对应项目文件夹，sh 1-build.sh

- ssh 进入对应部署的机器之后

- docker pull registry.cn-hangzhou.aliyuncs.com/applysqtsinghua/xxx

- 退出到本地 kubecfg update build.jsonnet

- 注意：假如报错说阿里云无法授权

    - ssh root@219.223.190.102  
    
    - 进入 102 之后再 ssh square@219.223.190.103 ssh square@219.223.190.104 (清华机器被限制，只能先进入102，再进入103、104)
    
    - 进入对应部署 的机器之后
    
    - docker login --username=xxxx --password=xxx registry.cn-hangzhou.aliyuncs.com（一次就好）

```

项目更新（临时）

```
- 进入对应项目文件夹，sh 1-build.sh

- kubectl -n sigs delete statefulsets.apps xxxx

- ssh 进入对应部署的机器之后

- docker image rm registry.cn-hangzhou.aliyuncs.com/applysqtsinghua/xxx

- docker pull registry.cn-hangzhou.aliyuncs.com/applysqtsinghua/xxx

- 退出到本地 kubecfg update build.jsonnet

```

# 网络层验证

部署完k8s集群以后，即使表面看起来一切正常，节点之间网络层需要额外手动验证。
其实就是在节点之间使用pod的ip互相ping一下。看看在不同节点的pod是否能够互相ping通。

rancher官方给了一套检查方法，应该使用该方法验证：
https://rancher.com/docs/rancher/v2.x/en/troubleshooting/networking/

# 网络层验证不通的可能问题

## k8s pod子网与已有主机子网重叠

例如某校私有网络是10.0.0.0/8，rancher默认启动的pod子网是10.84.0.0/16, 这种情况会出现网络层无法跑通。

解决方法，rancher中创建集群时，手动更改yaml配置文件，指定pod cidr （将如下信息手动merge入已有配置）:
```
  services:
    kube-api:
      service_cluster_ip_range: 172.21.0.0/16
    kube-controller:
      cluster_cidr: 172.20.0.0/16
      service_cluster_ip_range: 172.21.0.0/16
    kubelet:
      cluster_dns_server: 172.21.0.10
```

## 主机安装有误

因为某些原因导致主机安装中进行了一些额外不匹配操作，可能会导致该主机网络无法跑通，装机过程要严格记录步骤，按标准化执行。