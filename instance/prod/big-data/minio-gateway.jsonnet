local app = import '../../../libs/minio-gateway/base.libsonnet';

{
  app: app.makeComponent('sigs', 'prod'),
}