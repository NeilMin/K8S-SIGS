local a2 = import '../../common/a2.libsonnet';
local kube = a2.kube;

{
  makeComponent(namespace, name):: {
    local minioName = name + '-minio',
    local component = self,
    local nsMeta = a2.nsMeta(namespace),
    # Headless Service
    svc: kube.Service(minioName) + nsMeta + {
      target_pod:: component.sts.spec.template,
      spec: {
        clusterIP: 'None',
        # 不考虑是否准备就绪，以便于其他同行可以发现。
        publishNotReadyAddresses: true,
        ports: [
          {
            name: minioName,
            port: 9000,
          },
        ],
        selector: {
          name: minioName,
        },
      },
    },
    sts: kube.StatefulSet(minioName) + nsMeta {
      spec+: {
        # 以并行的方式创建和删除pod
        podManagementPolicy: 'Parallel',
        # 分布式部署至少4个
        replicas: 4,
        volumeClaimTemplates_: {
          data: kube.PersistentVolumeClaim('data') {
            storageClass: 'local-path',
            storage: '5Gi', 
          },
        },
        template+: {
          spec+: a2.Spot() + {
            containers_+: {
              minio: kube.Container('minio') {
                image: 'minio/minio',
                resources: {
                  requests: {
                    cpu: 0.2,
                    memory: '500M',
                  },
                },
                env_+: {
                  MINIO_ACCESS_KEY: 'admin', // 至少3个字符
                  MINIO_SECRET_KEY: 'XLu6VQHu1e4Qs4y8', // 至少8个字符
                },
                args: ['server', 'http://' + minioName + '-{0...3}.' + minioName + '.' + namespace + '.svc.cluster.local/data'],
                ports_+: {
                  http: {
                    containerPort: 9000,
                    hostPort: 9000,
                  },
                },
                # Liveness probe detects situations where MinIO server instance
                # is not working properly and needs restart. Kubernetes automatically
                # restarts the pods if liveness checks fail.
                livenessProbe: {
                  httpGet: {
                    path: '/minio/health/live',
                    port: 9000,
                  },
                  initialDelaySeconds: 120,
                  periodSeconds: 20,
                },
                # Readiness probe detects situations where MinIO server instance
                # is not ready to accept connections. Kubernetes automatically
                # stops all the traffic to the pods if readiness checks fail.
                readinessProbe: {
                  httpGet: {
                    path: '/minio/health/ready',
                    port: 9000,
                  },
                  initialDelaySeconds: 120,
                  periodSeconds: 20,
                },
                volumeMounts_: {
                  data: {
                    mountPath: '/data',
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
