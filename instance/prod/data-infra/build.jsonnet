local app = import '../../../libs/base.libsonnet';

{
  app: app.makeApp('sigs', 'prod', 'data-infra-management', 'registry.cn-hangzhou.aliyuncs.com/applysqtsinghua/data-infra-project-management:1', {
    HIVE_ROOT_USERNAME: 'root',
    HIVE_ROOT_PASSWORD_DEFAULT: 'kRJREA8e',
    LDAP_ADMIN_DN: 'cn=admin,dc=ldap,dc=applysquare,dc=org',
    LDAP_ADMIN_PASSWORD: 'prodadmin',
    DRILL_CONN_USER: 'mapr',
    HDFS_ROOT_USER: 'root',
    NAMESPACE: 'sigs',
    INSTANCE: 'prod',
  }, 'bd-node01', 'bd-node02', 8080),
}