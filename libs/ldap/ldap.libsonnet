local a2 = import '../../common/a2.libsonnet';
local kube = a2.kube;

{
  makeApp(namespace, name):: {
    local prefix = name + '-',
    local component = self,
    local nsMeta = a2.nsMeta(namespace),
    local ldapName = prefix + 'ldap',
    pvc: {
      lib: kube.PersistentVolumeClaim(ldapName + '-lib') + nsMeta + {
        storageClass: 'local-path',
        storage: '5Gi',
      },  
      etc: kube.PersistentVolumeClaim(ldapName + '-etc') + nsMeta + {
        storageClass: 'local-path',
        storage: '5Gi',
      },       
    }, 
    deploy: { 
      openldap: {
        svc: a2.DeploymentService(component.deploy.openldap.deploy) + nsMeta,
        deploy: kube.StatefulSet(ldapName + '-openldap') + nsMeta {
          spec+: {
            replicas: 1,
            template+: {
              spec+: a2.Spot() + {
                volumes_+: {
                  'openldap-lib': kube.PersistentVolumeClaimVolume(component.pvc.lib),
                  'openldap-etc': kube.PersistentVolumeClaimVolume(component.pvc.etc),
                },
                containers_+: {
                  default: kube.Container('default') {
                    image: 'applysq/openldap:2.5',
                    resources: {
                      requests: {
                        cpu: 0.2,
                        memory: '200M',
                      },
                    },
                    ports_+: {
                      'openldap-389': {
                        containerPort: 389,
                      },
                      'openldap-636': {
                        containerPort: 636,
                      },
                    },
                    env_+: {
                      SLAPD_ORGANIZATION: "Applysquare.",
                      SLAPD_DOMAIN: "ldap.applysquare.org",
                      SLAPD_PASSWORD: name + "admin",
                      SLAPD_CONFIG_PASSWORD: name + "config",
                    },
                    volumeMounts_+: {
                      'openldap-lib': {
                        mountPath: '/var/lib/ldap',
                      },
                      'openldap-etc': {
                        mountPath: '/etc/ldap',
                      },
                    },
                  },
                },
              },
            },
          },
        },
      },
      ldapadmin: {
        svc: a2.DeploymentService(component.deploy.ldapadmin.deploy) + nsMeta,
        deploy: kube.StatefulSet(ldapName + '-ldapadmin') + nsMeta {
          spec+: {
            replicas: 1,
            template+: {
              spec+: a2.Spot() + {
                containers_+: {
                  default: kube.Container('default') {
                    image: 'applysq/phpldapadmin:1.0',
                    resources: {
                      requests: {
                        cpu: 0.2,
                        memory: '200M',
                      },
                    },
                    ports_+: {
                      'ldapadmin-8080': {
                        containerPort: 80,
                         hostPort: 30298,
                      },
                    },
                    env_+: {
                      LDAP_SERVER_HOST: ldapName + '-openldap',
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
