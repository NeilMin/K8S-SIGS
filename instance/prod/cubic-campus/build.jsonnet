local app = import '../../../libs/base.libsonnet';

{
  app: app.makeApp('sigs', 'prod', 'cubic-campus', 'registry.cn-hangzhou.aliyuncs.com/applysqtsinghua/cubic-campus:1', {}, 'bd-node01', 'bd-node02', 8083),
}
