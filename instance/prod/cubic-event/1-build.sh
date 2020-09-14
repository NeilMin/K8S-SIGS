## 本地 build 过之后先执行删除会节省空间
kubectl -n sigs delete statefulsets.apps prod-cubic-event-frontend
docker image rm ma.applysquare.net:4567/eng/docker/cubic-event:1
docker image rm registry.cn-hangzhou.aliyuncs.com/applysqtsinghua/cubic-event:1

docker pull ma.applysquare.net:4567/eng/docker/cubic-event:1 
docker tag ma.applysquare.net:4567/eng/docker/cubic-event:1 registry.cn-hangzhou.aliyuncs.com/applysqtsinghua/cubic-event:1
docker push registry.cn-hangzhou.aliyuncs.com/applysqtsinghua/cubic-event:1

## 上述命令在本地执行完成之后，进入具体部署frontend的机器(219.223.190.103)，执行下面命令
## docker image rm registry.cn-hangzhou.aliyuncs.com/applysqtsinghua/cubic-event:1
## docker pull registry.cn-hangzhou.aliyuncs.com/applysqtsinghua/cubic-event:1

## 最后在本地执行kubecfg update build.jsonnet