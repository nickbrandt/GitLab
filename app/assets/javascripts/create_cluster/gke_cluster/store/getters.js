export const hasProject = state => Boolean(state.selectedProject.projectId);
export const hasZone = state => Boolean(state.selectedZone);
export const hasMachineType = state => Boolean(state.selectedMachineType);
export const projectId = state => state.selectedProject?.projectId;
export const region = ({ selectedZone }) =>
  selectedZone && selectedZone.substring(0, selectedZone.lastIndexOf('-'));
export const hasNetwork = state => Boolean(state.selectedNetwork?.selfLink);
export const hasSubnetwork = state => Boolean(state.selectedSubnetwork);
export const hasValidData = (state, getters) =>
  Boolean(state.projectHasBillingEnabled) && getters.hasZone && getters.hasMachineType;
