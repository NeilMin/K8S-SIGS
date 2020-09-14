local a2 = import '../../common/a2.libsonnet';
local kube = a2.kube;

{
  makeComponent(namespace, name):: {
    local component = self,
    local minioName = name + '-minio-gateway',
    local nsMeta = a2.nsMeta(namespace),
    svc: a2.DeploymentService(component.sts) + nsMeta,
    pvc: {
      data: kube.PersistentVolumeClaim(minioName + '-data') + nsMeta + {
        storageClass: 'local-path',
        storage: '5Gi',
      },
    },
    sts: kube.StatefulSet(minioName) + nsMeta {
      spec+: {
        template+: {
          spec+: a2.Spot() + {
            volumes_: {
              data: kube.PersistentVolumeClaimVolume(component.pvc.data),
            },
            containers_+: {
              default: kube.Container('default') {
                image: 'minio/minio',
                resources: {
                  requests: {
                    cpu: 0.2,
                    memory: '500M',
                  },
                },
                env_+: {
                  MINIO_ACCESS_KEY: 'admin', // 至少3个字符
                  MINIO_SECRET_KEY: 'Oh3bn0g2QKZGiUxx', // 至少8个字符
                },
                args: ['gateway', 'hdfs', 'hdfs://' + name + '-hdfs-namenode.' + namespace + '.svc:8020'],
                ports_+: {
                  http: {
                    containerPort: 9000,
                    hostPort: 9001,
                  },
                },
                volumeMounts_: {
                  data: {
                    mountPath: '/data',
                    subPath: 'data',
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
