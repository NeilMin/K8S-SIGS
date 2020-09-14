local a2 = import '../../common/a2.libsonnet';
local kube = a2.kube;

{
  makeApp(namespace, name):: {
    local prefix = name + '-sqoop-',
    local nsMeta = a2.nsMeta(namespace),
    local component = self,

    deploy: kube.StatefulSet(prefix + 'shell') + nsMeta {
      spec+: {
        replicas: 1,
        template+: {
          spec+: a2.Spot() + {
            containers_+: {
              default: kube.Container('default') {
                imagePullPolicy: 'Always',
                image: 'applysq/sqoop:1.4.7_hadoop_3.1.2_v3.1',
                resources: {
                  requests: {
                    cpu: 0.2,
                    memory: '200M',
                  },
                },
                tty: true,
                forceTTY_: true,
                command: ['bash', '-c'],
                args: [|||
                  /entrypoint.sh
                  echo 'started'
                  cat
                |||],
                env_+: {
                  CLUSTER_NAME: namespace + '-' + name + '-hadoop',
                  CORE_CONF_fs_defaultFS: 'hdfs://' + name + '-hdfs-namenode.' + namespace + '.svc:8020',
                  HIVE_CONF_hive_metastore_uris: 'thrift://' + name + '-hive-metastore:9083',
                  HIVE_CONF_hive_support_concurrency: 'true',
                  HIVE_CONF_hive_compactor_initiator_on: 'true',
                  HIVE_CONF_hive_compactor_worker_threads: '1',
                  HIVE_CONF_hive_txn_manager: 'org.apache.hadoop.hive.ql.lockmgr.DbTxnManager',
                  HIVE_CONF_hive_enforce_bucketing: 'true',
                  HIVE_CONF_hive_exec_dynamic_partition_mode: 'nonstrict',
                  MULTIHOMED_NETWORK: '0',
                },
              },
            },
          },
        },
      },
    },
  },
}
