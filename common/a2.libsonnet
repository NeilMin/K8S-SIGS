local kube = import '../common/kube.libsonnet';

local repoPath(name) = '/repos/' + name + '/repo';

{
  toolboxImage: 'applysq/toolbox:latest',
  kube:: kube,
  strNotEmpty(s):: std.isString(s) && s != '',
  makeArgs(s):: [s for s in std.split(s, '\n') if s != ''],
  reposVolumeMount:: {
    repos: {
      mountPath: '/repos',
    },
  },
  nsMeta(name):: {
    metadata+: {
      namespace: name,
    },
  },
  DeploymentService(deploy):: kube.Service(deploy.metadata.name) + $.nsMeta(deploy.metadata.namespace) {
    target_pod: deploy.spec.template,
  },
  MultiPortDeploymentService(deploy):: kube.Service(deploy.metadata.name) + $.nsMeta(deploy.metadata.namespace) {
    local service = self,
    target_pod:: deploy.spec.template,
    spec: {
      selector: service.target_pod.metadata.labels,
      ports: [{
        name: p.name,
        port: p.containerPort,
        targetPort: p.containerPort,
      } for p in service.target_pod.spec.containers[0].ports],
      type: "ClusterIP",
    },
  },
  ServiceIngress(svc, host):: $.SimpleIngress(svc.metadata.name, host) {
    servicePort: svc.port,
  },
  SecureServiceIngress(svc, host, secretName):: $.ServiceIngress(svc, host) {
    metadata+: {
      annotations+: {
        'certmanager.k8s.io/cluster-issuer': 'letsencrypt-prod',
      },
    },
    spec+: {
      tls: [{
        hosts: [host],
        secretName: secretName,
      }],
    },
  },  
  SimpleIngress(name, host, ingressName=''):: kube.Ingress(if ingressName != '' then ingressName else name) {
    local ingress = self,
    servicePort:: 80,
    metadata+: {
      annotations+: {
        'kubernetes.io/ingress.class': 'nginx',
        'nginx.ingress.kubernetes.io/force-ssl-redirect': 'true',
        'nginx.org/client-max-body-size': '0',
        'nginx.ingress.kubernetes.io/proxy-body-size': '0',
      },
    },
    spec: {
      rules: [{
        host: host,
        http: {
          paths: [
            {
              backend: {
                serviceName: name,
                servicePort: ingress.servicePort,
              },
            },
          ],
        },
      }],
    },
  },
  Spot(instancegroup=''):: {
    nodeSelector: if instancegroup != '' then  {
      'kops.k8s.io/instancegroup': 'spot.' + instancegroup,
    } else {},
    tolerations: [
      {
        key: 'a2/spot',
        operator: 'Exists',
        effect: 'NoSchedule'
      },
    ],
  },
  Pod(iam_role=null, gitlab_repos=[],
      download_go_release=false,
      prod_keys_volume=false,
      version_name='frontend'):: {
    local git_volumes = if std.length(gitlab_repos) > 0 || download_go_release then
      [
        {
          name: 'git-secret',
          secret: {
            secretName: 'gitlab-git-creds',
            defaultMode: 256,
          },
        },
        {
          name: 'repos',
          emptyDir: {},
        },
      ] else [],

    local prod_keys_volumes = if prod_keys_volume then
      [
        {
          name: 'a2-prod-keys',
          secret: {
            secretName: 'a2-prod-keys',
          },
        },
      ] else [],

    local go_release_container = if download_go_release then
      [
        $.GitSyncContainer({
          name: 'deployment',
          repo: 'eng/deployment',
          branch: 'master',
        }),
        kube.Container('sync-go-release') {
          image: $.toolboxImage,
          command: ['bash', '-c'],
          args: [|||
            set -x
            set -e
            VERSION=$(cat %s/%s_config.txt)
            echo $VERSION
            aws s3 sync s3://applysquare-binary/go_release/$VERSION /repos/go-release/prod
            chmod a+x /repos/go-release/prod/bin/*
          ||| % [repoPath('deployment'), version_name]],
          env_: {
            AWS_DEFAULT_REGION: 'cn-north-1',
          },
          volumeMounts_: $.reposVolumeMount,
        },
      ] else [],

    metadata+: {
      annotations+: {
        'iam.amazonaws.com/role':
          if $.strNotEmpty(iam_role) then
            'arn:aws-cn:iam::078703237370:role/k8s-' + iam_role
          else '',
      },
    },
    spec+: kube.PodSpec {
      imagePullSecrets+: [{
        name: 'gitlab-docker-repository',
      }],
      volumes+: git_volumes + prod_keys_volumes,
      initContainers+: [$.GitSyncContainer(p) for p in gitlab_repos] + go_release_container,
    },
  },
  GitSyncContainer(params):: kube.Container('git-sync-' + params.name) {
    name: 'git-sync-' + params.name,
    image: 'applysq/k8s.gcr.io_git-sync:v3.0.1',
    securityContext: {
      runAsUser: 0,
    },
    env: [
      {
        name: 'GIT_SYNC_REPO',
        value: 'git@ma.applysquare.net:' + params.repo + '.git',
      },
      {
        name: 'GIT_SYNC_BRANCH',
        value: params.branch,
      },
      {
        name: 'GIT_SYNC_SSH',
        value: 'true',
      },
      {
        name: 'GIT_SYNC_ROOT',
        value: '/repos/' + params.name,
      },
      {
        name: 'GIT_SYNC_DEST',
        value: 'repo',
      },
      {
        name: 'GIT_SYNC_ONE_TIME',
        value: 'true',
      },
    ],
    volumeMounts_: $.reposVolumeMount {
      git_secret: {
        mountPath: '/etc/git-secret',
      },
    },
  },
}
