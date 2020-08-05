const [{ value: kubernetesVersion }] = [{ name: '1.16', value: '1.16' }];

export default () => ({
  createRolePath: null,

  isCreatingRole: false,
  roleCreated: false,
  createRoleError: false,

  accountId: '',
  externalId: '',

  roleArn: '',

  clusterName: '',
  environmentScope: '*',
  kubernetesVersion,
  selectedRegion: '',
  selectedRole: '',
  selectedKeyPair: '',
  selectedVpc: '',
  selectedSubnet: [],
  selectedSecurityGroup: '',
  selectedInstanceType: 'm5.large',
  nodeCount: '3',

  isCreatingCluster: false,
  createClusterError: false,

  gitlabManagedCluster: true,
});
