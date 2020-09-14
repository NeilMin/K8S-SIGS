local a2 = import '../../common/a2.libsonnet';
local kube = a2.kube;

{
  makeApp(namespace, name, nodeSelector):: {
    local prefix = name + '-drill-',
    local component = self,
    local nsMeta = a2.nsMeta(namespace),
    svc: a2.MultiPortDeploymentService(component.sts) + nsMeta,
    sts: kube.StatefulSet(prefix + 'drillbit') + nsMeta {
      spec+: {
        replicas: 1,
        serviceName: prefix + 'drillbit',
        template+: {
          spec+: a2.Spot() + {
            nodeSelector: {
              'k8s.sigs/label': nodeSelector,
            },
            initContainers: [
              {
                name: 'zk-available',
                image: 'busybox',
                command: [
                  'sh',
                  '-c',
                  'until nc -z ' + name + '-zk-server 2181; do echo Waiting for ZK to come up; sleep 5; done; ',
                ],
              },
            ],
            containers_+: {
              default: kube.Container('default') {
                imagePullPolicy: 'Always',
                image: 'applysq/drill:1.16.0',
                resources: {
                  requests: {
                    cpu: 0.8,
                    memory: '800M',
                  },
                },
                command: ['bash', '-c'],
                args: [|||
                  set -x
                  set -e
                  # shamelessly copied from https://github.com/wurstmeister/drill-docker/blob/master/start-drill.sh

                  if [ ! -f $DRILL_HOME/conf/drill-override.conf ]; then
                    cp $DRILL_HOME/conf/drill-override-example.conf $DRILL_HOME/conf/drill-override.conf
                  fi
                  ZOOKEEPER_ADDRESS=${ZOOKEEPER_ADDRESS:-'zk-service:2181'}
                  sed -i "s/drillbits1/${CLUSTER_ID}/g" ./conf/drill-override.conf
                  sed -i "s/localhost:2181/${ZOOKEEPER_ADDRESS}/g" ./conf/drill-override.conf
                  cat ./conf/drill-override.conf
                  ./bin/drillbit.sh run
                |||],
                env_+: {
                  ZOOKEEPER_ADDRESS: name + '-zk-server:2181',
                  CLUSTER_ID: name + '-drill',
                },
                ports_+: {
                  http: {
                    containerPort: 8047,
                  },
                  userport: {
                    containerPort: 31010,
                  },
                  controlport: {
                    containerPort: 31011,
                  },
                  dataport: {
                    containerPort: 31012,
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
