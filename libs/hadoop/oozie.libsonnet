local a2 = import '../../common/a2.libsonnet';
local kube = a2.kube;

{
  makeApp(namespace, name, nodeSelector):: {
    local component = self,
    local oozieName = name + '-' + 'oozie',
    local nsMeta = a2.nsMeta(namespace),
    svc: a2.DeploymentService(component.deploy) + nsMeta,
    deploy: kube.StatefulSet(oozieName) + nsMeta {
      spec+: {
        template+: {
          spec+: a2.Spot() + {
            nodeSelector: {
              'k8s.sigs/label': nodeSelector,
            },
            containers_+: {
              default: kube.Container('default') {
                imagePullPolicy: 'Always',
                image: 'applysq/oozie:5.2.0',
                ports_+: {
                  'web-11000': {
                    containerPort: 11000,
                    hostPort: 11000,
                  },
                  'web-11001': {
                    containerPort: 11001,
                  },
                },
                tty: true,
                forceTTY_: true,
                command: ['bash', '-c'],
                args: [|||
                  set -x
                  set -e
                  /entrypoint.sh
                  cd $OOZIE_HOME
                  cp ./embedded-oozie-server/webapp/WEB-INF/lib/*.jar ./lib
                  cp libext/mysql-connector-java-5.1.48.jar ./lib
                  rm ./lib/guava-11.0.2.jar
                  rm ./embedded-oozie-server/webapp/WEB-INF/lib/guava-11.0.2.jar
                  cp ./lib/guava-27.0-jre.jar ./embedded-oozie-server/webapp/WEB-INF/lib
                  bin/ooziedb.sh create db -run
                  bin/oozied.sh run
                |||],
                resources: {
                  requests: {
                    cpu: 0.2,
                    memory: '200M',
                  },
                },
                env_+: {
                  CLUSTER_NAME: namespace + '-' + name + '-hadoop',
                  CORE_CONF_hadoop_proxyuser_root_hosts: '*',
                  CORE_CONF_hadoop_proxyuser_root_groups: '*',
                  CORE_CONF_fs_defaultFS: 'hdfs://' + name + '-hdfs-namenode.' + namespace + '.svc:8020',
                  OOZIE_CONF_oozie_service_JPAService_jdbc_url: 'jdbc:mysql://' + name + '-meta-mysql/ooziedb?useSSL=false',
                  OOZIE_CONF_oozie_service_JPAService_jdbc_driver: 'com.mysql.jdbc.Driver',
                  OOZIE_CONF_oozie_service_JPAService_jdbc_username: 'oozieuser',
                  OOZIE_CONF_oozie_service_JPAService_jdbc_password: 'ooziepassword',
                  OOZIE_CONF_oozie_service_HadoopAccessorService_hadoop_configurations: '*=/opt/hadoop-3.2.1/etc/hadoop',
                  OOZIE_CONF_oozie_service_ProxyUserService_proxyuser_root_hosts: '*',
                  OOZIE_CONF_oozie_service_ProxyUserService_proxyuser_root_groups: '*',
                  OOZIE_CONF_hadoop_proxyuser_root_hosts: '*',
                  OOZIE_CONF_hadoop_proxyuser_root_groups: '*',
                  OOZIE_CONF_oozie_service_CallbackService_base_url: 'http://' + name +'-oozie.' + namespace + '.svc:11000/oozie/callback',
                  OOZIE_CONF_oozie_action_max_output_data: '51200',
                  OOZIE_CONF_oozie_launcher_mapreduce_map_memory_mb: '512',
                  OOZIE_CONF_oozie_launcher_yarn_app_mapreduce_am_resource_mb: '512',
                  MAPRED_CONF_mapreduce_framework_name: 'yarn',
                  MAPRED_CONF_yarn_app_mapreduce_am_env: 'HADOOP_MAPRED_HOME=/opt/hadoop/etc/hadoop:/opt/hadoop/share/hadoop/common/lib/*:/opt/hadoop/share/hadoop/common/*:/opt/hadoop/share/hadoop/hdfs:/opt/hadoop/share/hadoop/hdfs/lib/*:/opt/hadoop/share/hadoop/hdfs/*:/opt/hadoop/share/hadoop/mapreduce/lib/*:/opt/hadoop/share/hadoop/mapreduce/*:/opt/hadoop/share/hadoop/yarn:/opt/hadoop/share/hadoop/yarn/lib/*:/opt/hadoop/share/hadoop/yarn/*',
                  MAPRED_CONF_mapreduce_map_env: 'HADOOP_MAPRED_HOME=/opt/hadoop/etc/hadoop:/opt/hadoop/share/hadoop/common/lib/*:/opt/hadoop/share/hadoop/common/*:/opt/hadoop/share/hadoop/hdfs:/opt/hadoop/share/hadoop/hdfs/lib/*:/opt/hadoop/share/hadoop/hdfs/*:/opt/hadoop/share/hadoop/mapreduce/lib/*:/opt/hadoop/share/hadoop/mapreduce/*:/opt/hadoop/share/hadoop/yarn:/opt/hadoop/share/hadoop/yarn/lib/*:/opt/hadoop/share/hadoop/yarn/*',
                  MAPRED_CONF_mapreduce_reduce_env: 'HADOOP_MAPRED_HOME=/opt/hadoop/etc/hadoop:/opt/hadoop/share/hadoop/common/lib/*:/opt/hadoop/share/hadoop/common/*:/opt/hadoop/share/hadoop/hdfs:/opt/hadoop/share/hadoop/hdfs/lib/*:/opt/hadoop/share/hadoop/hdfs/*:/opt/hadoop/share/hadoop/mapreduce/lib/*:/opt/hadoop/share/hadoop/mapreduce/*:/opt/hadoop/share/hadoop/yarn:/opt/hadoop/share/hadoop/yarn/lib/*:/opt/hadoop/share/hadoop/yarn/*',
                  MAPRED_CONF_mapreduce_jobhistory_address: name + '-yarn-resourcemanager.' + namespace + '.svc:10020',
                  MAPRED_CONF_mapreduce_jobhistory_webapp_address: name + '-yarn-resourcemanager.' + namespace +'.svc:19888',
                  YARN_CONF_yarn_resourcemanager_hostname: name + '-yarn-resourcemanager.' + namespace + '.svc',
                  YARN_CONF_yarn_resourcemanager_address: name + '-yarn-resourcemanager.' + namespace + '.svc:8032',
                  YARN_CONF_yarn_resourcemanager_scheduler_address: name + '-yarn-resourcemanager.' + namespace + '.svc:8030',
                  YARN_CONF_yarn_app_mapreduce_am_admin___command___opts: '-Dfile.encoding=UTF-8',
                  MULTIHOMED_NETWORK: '0',
                }
              },
            },
          },
        },
      },
    },
  },
}
