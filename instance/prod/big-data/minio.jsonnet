local app = import '../../../libs/minio/base.libsonnet';

{
  server: app.makeComponent('sigs', 'prod'),
}