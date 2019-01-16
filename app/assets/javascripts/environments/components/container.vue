<script>
import { GlLoadingIcon } from '@gitlab/ui';
import tablePagination from '../../vue_shared/components/table_pagination.vue';
import environmentTable from '../components/environments_table.vue';

export default {
  components: {
    environmentTable,
    tablePagination,
    GlLoadingIcon,
  },
  props: {
    isLoading: {
      type: Boolean,
      required: true,
    },
    environments: {
      type: Array,
      required: true,
    },
    pagination: {
      type: Object,
      required: true,
    },
    canCreateDeployment: {
      type: Boolean,
      required: true,
    },
    canReadEnvironment: {
      type: Boolean,
      required: true,
    },
    // ee-only start
    canaryDeploymentFeatureId: {
      type: String,
      required: true,
    },
    showCanaryDeploymentCallout: {
      type: Boolean,
      required: true,
    },
    userCalloutsPath: {
      type: String,
      required: true,
    },
    lockPromotionSvgPath: {
      type: String,
      required: true,
    },
    helpCanaryDeploymentsPath: {
      type: String,
      required: true,
    },
    // ee-only end
  },
  methods: {
    onChangePage(page) {
      this.$emit('onChangePage', page);
    },
  },
};
</script>

<template>
  <div class="environments-container">
    <gl-loading-icon
      v-if="isLoading"
      :size="3"
      class="prepend-top-default"
      label="Loading environments"
    />

    <slot name="emptyState"></slot>

    <div v-if="!isLoading && environments.length > 0" class="table-holder">
      <environment-table
        :environments="environments"
        :can-create-deployment="canCreateDeployment"
        :can-read-environment="canReadEnvironment"
        :canary-deployment-feature-id="canaryDeploymentFeatureId"
        :show-canary-deployment-callout="showCanaryDeploymentCallout"
        :user-callouts-path="userCalloutsPath"
        :lock-promotion-svg-path="lockPromotionSvgPath"
        :help-canary-deployments-path="helpCanaryDeploymentsPath"
      />

      <table-pagination
        v-if="pagination && pagination.totalPages > 1"
        :change="onChangePage"
        :page-info="pagination"
      />
    </div>
  </div>
</template>
