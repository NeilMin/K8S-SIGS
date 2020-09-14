local app = import '../../../libs/ldap/ldap.libsonnet';

{
  app: app.makeApp('sigs', 'prod'),
}