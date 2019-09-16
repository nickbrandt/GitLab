import { shallowMount } from '@vue/test-utils';

import ClusterFormDropdown from '~/create_cluster/eks_cluster/components/cluster_form_dropdown.vue';
import VpcDropdown from '~/create_cluster/eks_cluster/components/vpc_dropdown.vue';

describe('VpcDropdown', () => {
  let vm;

  const getClusterFormDropdown = () => vm.find(ClusterFormDropdown);

  beforeEach(() => {
    vm = shallowMount(VpcDropdown);
  });
  afterEach(() => vm.destroy());

  it('renders a cluster-form-dropdown', () => {
    expect(getClusterFormDropdown().exists()).toBe(true);
  });

  it('sets vpcs to cluster-form-dropdown items property', () => {
    const vpcs = [{ name: 'basic' }];

    vm.setProps({ vpcs });

    expect(getClusterFormDropdown().props('items')).toEqual(vpcs);
  });

  it('maps loading property to cluster-form-dropdown loading property', () => {
    const loading = true;

    vm.setProps({ loading });

    expect(getClusterFormDropdown().props('loading')).toEqual(loading);
  });

  it('sets a loading text', () => {
    expect(getClusterFormDropdown().props('loadingText')).toEqual('Loading VPCs');
  });

  it('maps disabled property to cluster-form-dropdown disabled property', () => {
    const disabled = true;

    vm.setProps({ disabled });

    expect(getClusterFormDropdown().props('disabled')).toEqual(disabled);
  });

  it('sets a disabled text', () => {
    expect(getClusterFormDropdown().props('disabledText')).toEqual(
      'Select a region to choose a VPC',
    );
  });

  it('sets a placeholder', () => {
    expect(getClusterFormDropdown().props('placeholder')).toEqual('Select a VPC');
  });

  it('sets an empty results text', () => {
    expect(getClusterFormDropdown().props('emptyText')).toEqual('No VPCs found');
  });

  it('sets a search field placeholder', () => {
    expect(getClusterFormDropdown().props('searchFieldPlaceholder')).toEqual('Search VPCs');
  });

  it('sets hasErrors property', () => {
    vm.setProps({ error: {} });

    expect(getClusterFormDropdown().props('hasErrors')).toEqual(true);
  });

  it('sets an error message', () => {
    expect(getClusterFormDropdown().props('errorMessage')).toEqual(
      'Could not load VPCs for the selected region',
    );
  });
});
