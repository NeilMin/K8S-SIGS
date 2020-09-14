local app = import '../../../libs/zookeeper/zookeeper.libsonnet';

{
  app: app.makeApp('sigs', 'prod'),
}