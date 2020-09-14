local a2 = import '../../common/a2.libsonnet';
local kube = a2.kube;

{
  makeApp(namespace, name):: {
    local prefix = name + '-hdfs-',
    local component = self,
    local nsMeta = a2.nsMeta(namespace),
    namenode: {
      svc: a2.MultiPortDeploymentService(component.namenode.sts) + nsMeta,
      sts: kube.StatefulSet(prefix + 'namenode') + nsMeta {
        spec+: {
          replicas: 1,
          volumeClaimTemplates_: {
            data: kube.PersistentVolumeClaim('data') {
              storageClass: 'local-path',
              storage: '1Gi',
            },
          },
          template+: {
            spec+: a2.Spot() + {
              containers_+: {
                default: kube.Container('default') {
                  imagePullPolicy: 'Always',
                  image: 'applysq/hadoop-namenode:3.2.1_v2',
                  resources: {
                    requests: {
                      cpu: 0.2,
                      memory: '200M',
                    },
                  },
                  ports_+: {
                    ui: {
                      containerPort: 9870,
                    },
                    ipc: {
                      containerPort: 8020,
                    },
                    httpfs: {
                      containerPort: 14000,
                    },
                  },
                  env_+: {
                    CLUSTER_NAME: namespace + '-' + name + '-hadoop',
                    // Allow root (whatever shell user) to act as any oher user.
                    CORE_CONF_hadoop_proxyuser_root_hosts: '*',
                    CORE_CONF_hadoop_proxyuser_root_groups: '*',
                    // CORE_CONF_fs_defaultFS: 'hdfs://' + component.namenode.svc.metadata.name + '.' + namespace + '.svc:8020',
                    // https://hadoop.apache.org/docs/r3.2.1/hadoop-project-dist/hadoop-hdfs/hdfs-default.xml
                    HDFS_CONF_dfs_namenode_datanode_registration_ip___hostname___check: 'false',
                    HDFS_CONF_dfs_block_size: '1048576',
                    HDFS_CONF_dfs_datanode_address:'0.0.0.0:9866',
                    HDFS_CONF_dfs_client_block_write_replace___datanode___on___failure_enable: 'true',
                    HDFS_CONF_dfs_client_block_write_replace___datanode___on___failure_policy: 'NEVER',
                    MULTIHOMED_NETWORK: '0',
                    HTTPFS_CONF_httpfs_proxyuser_root_hosts: '*',
                    HTTPFS_CONF_httpfs_proxyuser_root_groups: '*',
                  },
                  volumeMounts_+: {
                    data: {
                      mountPath: '/hadoop/dfs/name',
                      subPath: 'nameData',
                    },
                  },
                },
              },
            },
          },
        },
      },
    },
    datanode: {
      svc: a2.MultiPortDeploymentService(component.datanode.sts) + nsMeta,
      sts: kube.StatefulSet(prefix + 'datanode') + nsMeta {
        spec+: {
          replicas: 3,
          volumeClaimTemplates_: {
            data: kube.PersistentVolumeClaim('data') {
              storageClass: 'local-path',
              storage: '8Gi',
            },
          },
          template+: {
            spec+: a2.Spot() + {
              containers_+: {
                default: kube.Container('default') {
                  imagePullPolicy: 'Always',
                  image: 'applysq/hadoop-datanode:3.2.1',
                  resources: {
                    requests: {
                      cpu: 0.2,
                      memory: '200M',
                    },
                  },
                  ports_+: {
                    ui: {
                      containerPort: 9864,
                    },
                    data: {
                      containerPort: 9866,
                    },
                    ipc: {
                      containerPort: 9867,
                    },
                  },
                  env_+: {
                    CORE_CONF_fs_defaultFS: 'hdfs://' + component.namenode.svc.metadata.name + '.' + namespace + '.svc:8020',
                    HDFS_CONF_dfs_namenode_datanode_registration_ip___hostname___check: 'false',
                    HDFS_CONF_dfs_datanode_address: '0.0.0.0:9866',
                  },
                  volumeMounts_+: {
                    data: {
                      mountPath: '/hadoop/dfs/data',
                      subPath: 'dataData',
                    },
                  },
                },
              },
            },
          },
        },
      },
    },
  },
}
