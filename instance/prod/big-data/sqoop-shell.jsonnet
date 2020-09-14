local app = import '../../../libs/hadoop/sqoop-shell.libsonnet';

{
  app: app.makeApp('sigs', 'prod'),
}
