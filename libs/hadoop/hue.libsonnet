local a2 = import '../../common/a2.libsonnet';
local kube = a2.kube;

{
  makeApp(namespace, name):: {
    local component = self,
    local hueName = name + '-' + 'hue',
    local nsMeta = a2.nsMeta(namespace),
    svc: a2.DeploymentService(component.deploy) + nsMeta,
    deploy: kube.StatefulSet(hueName) + nsMeta {
      spec+: {
        template+: {
          spec+: a2.Spot() + {
            containers_+: {
              default: kube.Container('default') {
                imagePullPolicy: 'Always',
                image: 'applysq/hue:1.0.1_' + name,
                ports_+: {
                  ui: {
                    containerPort: 8888,
                    hostPort: 8888,
                  },
                },
                resources: {
                  requests: {
                    cpu: 0.2,
                    memory: '200M',
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

