import { KUBERNETES_VERSIONS } from '../constants';

export default () => ({
  isValidatingCredentials: false,
  hasCredentials: false,
  invalidCredentials: false,
  invalidCredentialsError: null,
  accountId: '',
  externalId: '',

  clusterName: '',
  environmentScope: '*',
  kubernetesVersion: [KUBERNETES_VERSIONS].value,
  selectedRegion: '',
  selectedRole: '',
  selectedKeyPair: '',
  selectedVpc: '',
  selectedSubnet: '',
  selectedSecurityGroup: '',

  gitlabManagedCluster: true,
});
