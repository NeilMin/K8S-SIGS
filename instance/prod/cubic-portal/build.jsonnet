local app = import '../../../libs/base.libsonnet';

{
  app: app.makeApp('sigs', 'prod', 'cubic-portal', 'registry.cn-hangzhou.aliyuncs.com/applysqtsinghua/cubic-portal:1', {
    ALICLOUD_SMS_REGION_ID:  'cn-hangzhou',
    ALICLOUD_SMS_ACCESS_KEY_ID:  'LTAI4GJPgEhwaxt6Mna1yYDr',
    ALICLOUD_SMS_ACCESS_KEY_SECRET:  'rFgtaFgHFO58VepJlrCy9Y29opTjTR',
  }, 'bd-node01', 'bd-node02', 8081),
}
