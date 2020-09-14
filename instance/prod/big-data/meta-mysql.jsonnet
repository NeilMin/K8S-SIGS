local app = import '../../../libs/mysql/mysql.libsonnet';

{
  app: app.makeApp('sigs', 'prod-meta', data='1Gi'),
}
