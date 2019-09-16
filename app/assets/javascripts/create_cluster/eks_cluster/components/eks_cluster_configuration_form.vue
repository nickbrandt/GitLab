<script>
import { createNamespacedHelpers, mapState, mapActions } from 'vuex';
import RegionDropdown from './region_dropdown.vue';
import RoleNameDropdown from './role_name_dropdown.vue';
import SecurityGroupDropdown from './security_group_dropdown.vue';
import SubnetDropdown from './subnet_dropdown.vue';
import VpcDropdown from './vpc_dropdown.vue';

const { mapState: mapRegionsState, mapActions: mapRegionsActions } = createNamespacedHelpers(
  'regions',
);

export default {
  components: {
    RegionDropdown,
    RoleNameDropdown,
    SecurityGroupDropdown,
    SubnetDropdown,
    VpcDropdown,
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
      <vpc-dropdown
        :input="selectedVpc"
        :vpcs="vpcs"
        :error="loadingVpcsError"
        :loading="isLoadingVpcs"
        :disabled="vpcDropdownDisabled"
        @input="setVpc({ vpc: $event })"
      />
    </div>
  </form>
</template>
