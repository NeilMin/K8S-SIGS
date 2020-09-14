local a2 = import '../../common/a2.libsonnet';
local kube = a2.kube;

{
  makeApp(namespace, name):: {
    local prefix = name + '-hive-',
    local nsMeta = a2.nsMeta(namespace),
    local component = self,
    local hiveSts(srvName, ports) = kube.StatefulSet(prefix + srvName) + nsMeta {
      spec+: {
        replicas: 1,
        template+: {
          spec+: a2.Spot() + {
            containers_+: {
              default: kube.Container('default') {
                imagePullPolicy: 'Always',
                image: 'applysq/hive:2.3.6',
                resources: {
                  requests: {
                    cpu: 0.2,
                    memory: '400M',
                  },
                },
                tty: true,
                forceTTY_: true,
                command: ['bash', '-c'],
                args: [std.format(|||
                  set -x
                  set -e
                  export HADOOP_HEAPSIZE="1024"
                  export HADOOP_CLIENT_OPTS="-Xmx512m $HADOOP_CLIENT_OPTS" 
                  bash /entrypoint.sh
                  cd $HIVE_HOME
                  bin/hive --service %s
                |||, srvName)],
                ports_+: ports,
                env_+: {
                  CLUSTER_NAME: namespace + '-' + name + '-hadoop',
                  CORE_CONF_fs_defaultFS: 'hdfs://' + name + '-hdfs-namenode.' + namespace + '.svc:8020',
                  MULTIHOMED_NETWORK: '0',
                  HIVE_CONF_javax_jdo_option_ConnectionURL: 'jdbc:mysql://' + name + '-meta-mysql/metastore?useUnicode=true&amp;characterEncoding=UTF-8&amp;useSSL=false',
                  HIVE_CONF_javax_jdo_option_ConnectionDriverName: 'com.mysql.jdbc.Driver',
                  HIVE_CONF_javax_jdo_option_ConnectionUserName: 'hiveuser',
                  HIVE_CONF_javax_jdo_option_ConnectionPassword: 'hivepassword',
                  HIVE_CONF_hive_server2_webui_host: '0.0.0.0',
                  HIVE_CONF_hive_server2_thrift_bind_host: '0.0.0.0',
                  HIVE_CONF_hive_support_concurrency: 'true',
                  HIVE_CONF_hive_compactor_initiator_on: 'true',
                  HIVE_CONF_hive_compactor_worker_threads: '1',
                  HIVE_CONF_hive_txn_manager: 'org.apache.hadoop.hive.ql.lockmgr.DbTxnManager',
                  HIVE_CONF_hive_enforce_bucketing: 'true',
                  HIVE_CONF_hive_exec_dynamic_partition_mode: 'nonstrict',
                  HIVE_CONF_hive_server2_authentication: 'LDAP',
                  HIVE_CONF_hive_server2_authentication_ldap_url: 'ldap://' + name + '-ldap-openldap.' + namespace + '.svc:389',
                  HIVE_CONF_hive_server2_authentication_ldap_baseDN: 'ou=People,dc=ldap,dc=applysquare,dc=org',
                  HIVE_CONF_hive_security_authorization_enabled: 'true',
                  HIVE_CONF_hive_security_authorization_createtable_owner_grants: 'ALL',
                  HIVE_CONF_hive_users_in_admin_role: 'admin_role,root',
                  HIVE_CONF_hive_metastore_schema_erification: 'false',
                  HIVE_CONF_hive_server2_enable_doAs: 'false',
                  HIVE_CONF_hive_security_authorization_manager: 'org.apache.hadoop.hive.ql.security.authorization.plugin.sqlstd.SQLStdHiveAuthorizerFactory',
                  HIVE_CONF_hive_security_authenticator_manager: 'org.apache.hadoop.hive.ql.security.SessionStateUserAuthenticator',
                  HIVE_CONF_hive_metastore_uris: 'thrift://' + name + '-hive-metastore:9083',
                  HIVE_CONF_datanucleus_schema_autoCreateAll: 'true',
                },
              },
            },
          },
        },
      },
    },
    svcHiveserver2: a2.MultiPortDeploymentService(component.hiveserver2),
    hiveserver2: hiveSts('hiveserver2', {
      hiveserver2: {
        containerPort: 10000,
        hostPort: 10000,
      },
    }),
    svcMetastore: a2.MultiPortDeploymentService(component.metastore),
    metastore: hiveSts('metastore', {
      metastore: {
        containerPort: 9083,
      },
    }),
  },
}
