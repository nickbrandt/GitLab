<script>
import { createNamespacedHelpers, mapState, mapActions } from 'vuex';
import { sprintf, s__ } from '~/locale';
import ClusterFormDropdown from './cluster_form_dropdown.vue';
import RegionDropdown from './region_dropdown.vue';
import RoleNameDropdown from './role_name_dropdown.vue';
import SecurityGroupDropdown from './security_group_dropdown.vue';
import SubnetDropdown from './subnet_dropdown.vue';

const { mapState: mapRegionsState, mapActions: mapRegionsActions } = createNamespacedHelpers(
  'regions',
);

export default {
  components: {
    ClusterFormDropdown,
    RegionDropdown,
    RoleNameDropdown,
    SecurityGroupDropdown,
    SubnetDropdown,
  },
  computed: {
    ...mapState(['selectedRegion']),
    ...mapRegionsState({
      regions: 'items',
      isLoadingRegions: 'isLoadingItems',
      loadingRegionsError: 'loadingItemsError',
    }),
    ...mapState('vpcs', {
      vpcs: ({ items }) => items,
      isLoadingVpcs: ({ isLoadingItems }) => isLoadingItems,
      loadingVpcsError: ({ loadingItemsError }) => loadingItemsError,
    }),
    vpcDropdownDisabled() {
      return !Boolean(this.selectedRegion);
    },
    vpcDropdownHelpText() {
      return sprintf(
        s__(
          'ClusterIntegration|Select a VPC to use for your EKS Cluster resources. To use a new VPC, first create one on %{startLink}Amazon Web Services%{endLink}.',
        ),
        {
          startLink:
            '<a href="https://console.aws.amazon.com/vpc/home?#vpc" target="_blank" rel="noopener noreferrer">',
          endLink: '</a>',
        },
        false,
      );
    },
  },
  mounted() {
    this.fetchRegions();
  },
  methods: {
    ...mapActions(['setRegion', 'setVpc']),
    ...mapActions({
      fetchRegions: 'regions/fetchItems',
      fetchVpcs: 'vpcs/fetchItems',
    }),
    setRegionAndFetchVpcs(region) {
      this.setRegion({ region });
      this.fetchVpcs({ region });
    },
  },
};
</script>
<template>
  <form name="eks-cluster-configuration-form">
    <div class="form-group">
      <label class="label-bold" name="role" for="eks-role">{{
        s__('ClusterIntegration|Role name')
      }}</label>
      <role-name-dropdown />
    </div>
    <div class="form-group">
      <label class="label-bold" name="role" for="eks-role">{{
        s__('ClusterIntegration|Region')
      }}</label>
      <region-dropdown
        :value="selectedRegion"
        :regions="regions"
        :error="loadingRegionsError"
        :loading="isLoadingRegions"
        @input="setRegionAndFetchVpcs($event)"
      />
    </div>
    <div class="form-group">
      <label class="label-bold" name="role" for="eks-role">{{
        s__('ClusterIntegration|VPC')
      }}</label>
      <cluster-form-dropdown
        field-id="eks-vpc"
        field-name="eks-vpc"
        :input="selectedVpc"
        :items="vpcs"
        :loading="isLoadingVpcs"
        :disabled="vpcDropdownDisabled"
        :disabled-text="s__('ClusterIntegration|Select a region to choose a VPC')"
        :loading-text="s__('ClusterIntegration|Loading VPCs')"
        :placeholder="s__('ClusterIntergation|Select a VPC')"
        :search-field-placeholder="s__('ClusterIntegration|Search VPCs')"
        :empty-text="s__('ClusterIntegration|No VPCs found')"
        :has-errors="loadingVpcsError"
        :error-message="s__('ClusterIntegration|Could not load VPCs for the selected region')"
        @input="setVpc({ vpc: $event })"
      />
      <p class="form-text text-muted" v-html="vpcDropdownHelpText"></p>
    </div>
  </form>
</template>
