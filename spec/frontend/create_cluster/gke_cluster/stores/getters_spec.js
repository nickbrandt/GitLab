import {
  hasProject,
  hasZone,
  hasMachineType,
  hasValidData,
  hasNetwork,
  hasSubnetwork,
} from '~/create_cluster/gke_cluster/store/getters';
import {
  selectedProjectMock,
  selectedZoneMock,
  selectedNetworkMock,
  selectedSubnetworkMock,
  selectedMachineTypeMock,
} from '../mock_data';

describe('GCP Cluster Dropdown Store Getters', () => {
  let state;

  describe('valid states', () => {
    beforeEach(() => {
      state = {
        projectHasBillingEnabled: true,
        selectedProject: selectedProjectMock,
        selectedZone: selectedZoneMock,
        selectedMachineType: selectedMachineTypeMock,
        selectedNetwork: selectedNetworkMock,
        selectedSubnetwork: selectedSubnetworkMock,
      };
    });

    describe('hasProject', () => {
      it('should return true when project is selected', () => {
        expect(hasProject(state)).toEqual(true);
      });
    });

    describe('hasZone', () => {
      it('should return true when zone is selected', () => {
        expect(hasZone(state)).toEqual(true);
      });
    });

    describe('hasMachineType', () => {
      it('should return true when machine type is selected', () => {
        expect(hasMachineType(state)).toEqual(true);
      });
    });

    describe('hasValidData', () => {
      it('should return true when a project, zone and machine type are selected', () => {
        expect(hasValidData(state, { hasZone: true, hasMachineType: true })).toEqual(true);
      });
    });

    describe('hasNetwork', () => {
      it('should return true when network is selected', () => {
        expect(getters.hasNetwork(state)).toEqual(true);
      });
    });

    describe('hasSubnetwork', () => {
      it('should return true when subnetwork is selected', () => {
        expect(getters.hasSubnetwork(state)).toEqual(true);
      });
    });
  });

  describe('invalid states', () => {
    beforeEach(() => {
      state = {
        selectedProject: {
          projectId: '',
          name: '',
        },
        selectedZone: '',
        selectedMachineType: '',
        selectedNetwork: {
          selfLink: '',
        },
        selectedSubnetwork: '',
      };
    });

    describe('hasProject', () => {
      it('should return false when project is not selected', () => {
        expect(hasProject(state)).toEqual(false);
      });
    });

    describe('hasZone', () => {
      it('should return false when zone is not selected', () => {
        expect(hasZone(state)).toEqual(false);
      });
    });

    describe('hasMachineType', () => {
      it('should return false when machine type is not selected', () => {
        expect(hasMachineType(state)).toEqual(false);
      });
    });

    describe('hasValidData', () => {
      let getters;

      beforeEach(() => {
        getters = { hasZone: true, hasMachineType: true };
      });

      it('should return false when project is not billable', () => {
        state.projectHasBillingEnabled = false;

        expect(hasValidData(state, getters)).toEqual(false);
      });

      it('should return false when zone is not selected', () => {
        getters.hasZone = false;

        expect(hasValidData(state, getters)).toEqual(false);
      });

      it('should return false when machine type is not selected', () => {
        getters.hasMachineType = false;

        expect(hasValidData(state, getters)).toEqual(false);
      });
    });

    describe('hasNetwork', () => {
      it('should return true when subnetwork is selected', () => {
        expect(getters.hasNetwork(state)).toEqual(false);
      });
    });

    describe('hasSubnetwork', () => {
      it('should return true when subnetwork is selected', () => {
        expect(getters.hasSubnetwork(state)).toEqual(false);
      });
    });
  });
});
