
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