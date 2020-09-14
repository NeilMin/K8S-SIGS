local app = import '../../../libs/base.libsonnet';

{
  app: app.makeApp('sigs', 'prod', 'cubic-event', 'registry.cn-hangzhou.aliyuncs.com/applysqtsinghua/cubic-event:1', {
    WX_APP_ID: 'wx76ca67fc5a85d365',
    WX_SECRET: '48e804e9b19e6ebc13697e97f1a140c8',
    WX_JS_CHECK_FILE_NAME: 'MP_verify_Cxx5eDp8U8KqHsbK.txt',
    WX_JS_CHECK_FILE_CONTENT: 'Cxx5eDp8U8KqHsbK',
  }, 'bd-node01', 'bd-node02', 8082),
}
