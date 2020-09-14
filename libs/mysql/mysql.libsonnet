local a2 = import '../../common/a2.libsonnet';
local kube = a2.kube;

{
  makeApp(namespace, name, cpu='0.1', ram='1Gi', data='10Gi'):: {
    local prefix = name + '-',
    local component = self,
    local mysqlName = prefix + 'mysql',
    local nsMeta = a2.nsMeta(namespace),
    deploy: kube.StatefulSet(mysqlName) + nsMeta {
      spec+: {
        volumeClaimTemplates_: {
          data: kube.PersistentVolumeClaim('data') {
            storageClass: 'local-path',
            storage: data,
          },
        },
        template+: {
          spec+: a2.Spot() + {
            containers_+: {
              default: kube.Container('default') {
                image: 'applysq/mysql:5',
                args: ['--ignore-db-dir=lost+found'],
                ports_+: {
                  mysql: {
                    containerPort: 3306,
                  },
                },
                resources: {
                  requests: {
                    cpu: cpu,
                    memory: ram,
                  },
                  limits: {
                    cpu: cpu,
                  },
                },
                env_+: {
                  MYSQL_ROOT_PASSWORD: kube.SecretKeyRef(component.secrets.mysql, 'password'),
                },
                volumeMounts_+: {
                  data: {
                    mountPath: '/var/lib/mysql',
                  },
                },
              },
            },
          },
        },
      },
    },
    svc: a2.DeploymentService(component.deploy) + nsMeta,
    secrets: {
      mysql: kube.Secret(prefix + 'mysql') + nsMeta {
        data_+: {
          password: 'password',
        },
      },
    },
  },
}
