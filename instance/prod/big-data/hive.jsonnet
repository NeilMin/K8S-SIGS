local app = import '../../../libs/hadoop/hive.libsonnet';

{
  app: app.makeApp('sigs', 'prod'),
}