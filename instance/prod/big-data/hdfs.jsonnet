local app = import '../../../libs/hadoop/hdfs.libsonnet';

{
  app: app.makeApp('sigs', 'prod'),
}