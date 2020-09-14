local app = import '../../../libs/drill/drill.libsonnet';

{
  app: app.makeApp('sigs', 'prod', 'srv-k8s-33'),
}
