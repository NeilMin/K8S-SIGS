local a2 = import '../common/a2.libsonnet';
local kube = a2.kube;

{
  makeApp(namespace, name, projectName, image, envs, frontendNodeSelector, postgresNodeSelector, hostPort):: {
    local component = self,
    local nsMeta = a2.nsMeta(namespace),
    local baseName = name + '-' + projectName,
    pvc: {
      postgres: kube.PersistentVolumeClaim(baseName + '-postgres') + nsMeta + {
        storageClass: 'local-path',
        storage: '5Gi',
      },
    },
    servers: {
      frontend: {
        svc: a2.DeploymentService(component.servers.frontend.sts) + nsMeta,
        sts: kube.StatefulSet(baseName + '-frontend') + nsMeta {
          spec+: {
            template+: {
              spec+: a2.Spot() + {
                nodeSelector: {
                  'k8s.sigs/label': frontendNodeSelector,
                },
                containers_+: {
                  default: kube.Container('default') {
                    image: image,
                    resources: {
                      requests: {
                        cpu: 0.2,
                        memory: '200M',
                      },
                    },
                    env_+: {
                      FLORA_DB_HOST: baseName + '-postgres.' + namespace + '.svc.cluster.local',
                      FLORA_DB_USER: namespace + '-' + baseName,
                      FLORA_DB_PASSWORD: namespace + '-' + baseName,
                      FLORA_DB_NAME: namespace + '-' + baseName,
                    } + envs,
                    command: ['sh', '-c'],
                    args: [|||
                      set -e
                      set -x
                      ./stage/bin/appserver updatedb --create_db
                      exec ./stage/bin/appserver server
                    |||],
                    ports_+: {
                      http: {
                        containerPort: 8080,
                        hostPort: hostPort,
                      },
                    },
                  },
                  node: kube.Container('node') {
                    image: image,
                    resources: {
                      requests: {
                        cpu: 0.2,
                        memory: '200M',
                      },
                    },
                    command: ['sh', '-c'],
                    args: [|||
                      cd stage/node/fumi
                      exec node server.js
                    |||],
                    ports_+: {
                      http: {
                        containerPort: 3000,
                      },
                    },
                  },
                },
              },
            },
          },
        },
      },
      postgres: {
        svc: a2.DeploymentService(component.servers.postgres.sts) + nsMeta,
        sts: kube.StatefulSet(baseName + '-postgres') + nsMeta {
          spec+: {
            serviceName: baseName + '-postgres',
            template+: {
              spec+: a2.Spot() + {
                volumes_: {
                  postgres: kube.PersistentVolumeClaimVolume(component.pvc.postgres),
                },
                nodeSelector: {
                  'k8s.sigs/label': postgresNodeSelector,
                },
                containers_+: {
                  default: kube.Container('default') {
                    image: 'registry.cn-hangzhou.aliyuncs.com/applysqtsinghua/flora-postgres:12',
                    resources: {
                      requests: {
                        cpu: 0.2,
                        memory: '200M',
                      },
                    },
                    env_+: {
                      POSTGRES_PASSWORD: namespace + '-' + baseName,
                      POSTGRES_USER: namespace + '-' + baseName,
                    },
                    ports_+: {
                      postgres: {
                        containerPort: 5432,
                      },
                    },
                    volumeMounts_: {
                      postgres: {
                        mountPath: '/var/lib/postgresql/data',
                        subPath: 'data',
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
}

