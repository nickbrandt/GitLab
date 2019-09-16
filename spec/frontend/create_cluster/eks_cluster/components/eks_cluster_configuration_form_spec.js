import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import Vue from 'vue';
import EksClusterConfigurationForm from '~/create_cluster/eks_cluster/components/eks_cluster_configuration_form.vue';
import RegionDropdown from '~/create_cluster/eks_cluster/components/region_dropdown.vue';
import VpcDropdown from '~/create_cluster/eks_cluster/components/vpc_dropdown.vue';

import clusterDropdownStoreState from '~/create_cluster/eks_cluster/store/cluster_dropdown/state';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('EksClusterConfigurationForm', () => {
  let store;
  let actions;
  let regionsState;
  let vpcsState;
  let vpcsActions;
  let regionsActions;
  let vm;

  beforeEach(() => {
    actions = {
      setRegion: jest.fn(),
      setVpc: jest.fn(),
    };
    regionsActions = {
      fetchItems: jest.fn(),
    };
    vpcsActions = {
      fetchItems: jest.fn(),
    };
    regionsState = {
      ...clusterDropdownStoreState(),
    };
    vpcsState = {
      ...clusterDropdownStoreState(),
    };
    store = new Vuex.Store({
      actions,
      modules: {
        vpcs: {
          namespaced: true,
          state: vpcsState,
          actions: vpcsActions,
        },
        regions: {
          namespaced: true,
          state: regionsState,
          actions: regionsActions,
        },
      },
    });
  });

  beforeEach(() => {
    vm = shallowMount(EksClusterConfigurationForm, {
      localVue,
      store,
    });
  });

  afterEach(() => {
    vm.destroy();
  });

  const findRegionDropdown = () => vm.find(RegionDropdown);
  const findVpcDropdown = () => vm.find(VpcDropdown);

  describe('when mounted', () => {
    it('fetches available regions', () => {
      expect(regionsActions.fetchItems).toHaveBeenCalled();
    });
  });

  it('sets isLoadingRegions to RegionDropdown loading property', () => {
    regionsState.isLoadingItems = true;

    return Vue.nextTick().then(() => {
      expect(findRegionDropdown().props('loading')).toEqual(regionsState.isLoadingItems);
    });
  });

  it('sets regions to RegionDropdown regions property', () => {
    expect(findRegionDropdown().props('regions')).toEqual(regionsState.items);
  });

  it('sets loadingRegionsError to RegionDropdown error property', () => {
    expect(findRegionDropdown().props('error')).toEqual(regionsState.loadingItemsError);
  });

  describe('when region is selected', () => {
    const region = { name: 'us-west-2' };

    beforeEach(() => {
      findRegionDropdown().vm.$emit('input', region);
    });

    it('dispatches setRegion action', () => {
      expect(actions.setRegion).toHaveBeenCalledWith(expect.anything(), { region }, undefined);
    });

    it('fetches available vpcs', () => {
      expect(vpcsActions.fetchItems).toHaveBeenCalledWith(expect.anything(), { region }, undefined);
    });
  });

  it('disables VpcDropdown when no region is selected', () => {
    expect(findVpcDropdown().props('disabled')).toEqual(true);
  });

  it('sets isLoadingVpcs to VpcDropdown loading property', () => {
    vpcsState.isLoadingItems = true;

    return Vue.nextTick().then(() => {
      expect(findVpcDropdown().props('loading')).toEqual(vpcsState.isLoadingItems);
    });
  });

  it('sets vpcs to VpcDropdown vpcs property', () => {
    expect(findVpcDropdown().props('vpcs')).toEqual(vpcsState.items);
  });

  it('sets loadingVpcsError to VpcDropdown error property', () => {
    expect(findVpcDropdown().props('error')).toEqual(vpcsState.loadingItemsError);
  });

  it('dispatches setVpc action when vpc is selected', () => {
    const vpc = { name: 'vpc-1' };

    findVpcDropdown().vm.$emit('input', vpc);

    expect(actions.setVpc).toHaveBeenCalledWith(expect.anything(), { vpc }, undefined);
  })
});
