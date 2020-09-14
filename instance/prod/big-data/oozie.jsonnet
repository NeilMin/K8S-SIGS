local app = import '../../../libs/hadoop/oozie.libsonnet';

{
  app: app.makeApp('sigs', 'prod', 'srv-k8s-33'),
}
