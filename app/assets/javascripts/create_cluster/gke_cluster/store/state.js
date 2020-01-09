export default () => ({
  selectedProject: {
    projectId: '',
    name: '',
  },
  selectedZone: '',
  selectedMachineType: '',
  selectedNetwork: {
    id: '',
    selfLink: '',
  },
  selectedSubnetwork: '',
  isValidatingProjectBilling: null,
  projectHasBillingEnabled: null,
  projects: [],
  zones: [],
  machineTypes: [],
});
