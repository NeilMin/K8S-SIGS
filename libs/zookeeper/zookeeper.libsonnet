local a2 = import '../../common/a2.libsonnet';

local kube = a2.kube;

{
  makeApp(namespace, name):: {
    local prefix = name + '-zk-',
    local nsMeta = a2.nsMeta(namespace),
    local component = self,
    local zkName = prefix + 'server',
    svc: a2.MultiPortDeploymentService(self.sts) + nsMeta {},
    sts: kube.StatefulSet(zkName) + nsMeta {
      spec+: {
        serviceName: zkName,
        replicas: 1,
        volumeClaimTemplates_: {
          data: kube.PersistentVolumeClaim('data') {
            storageClass: 'local-path',
            storage: '2Gi',
          },
        },
        template+: {
          spec+: a2.Spot() + {
            containers_+: {
              default: kube.Container('default') {
                image: 'applysq/zookeeper:3.5.6',
                resources: {
                  requests: {
                    cpu: 0.2,
                    memory: '200M',
                  },
                },
                volumeMounts_+: {
                  // Snapshot.
                  data: {
                    name: 'data',
                    mountPath: '/data',
                    subPath: 'data',
                  },
                  // Transaction log.
                  dataLog: {
                    name: 'data',
                    mountPath: '/datalog',
                    subPath: 'datalog',
                  },
                },
                ports_+: {
                  client: {
                    containerPort: 2181,
                  },
                  server: {
                    containerPort: 2888,
                  },
                  'leader-election': {
                    containerPort: 3888,
                  },
                  admin: {
                    // Interesting paths: /commands
                    containerPort: 8080,
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