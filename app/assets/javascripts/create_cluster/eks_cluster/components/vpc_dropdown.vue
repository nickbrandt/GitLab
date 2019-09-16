<script>
import { sprintf, s__ } from '~/locale';

import ClusterFormDropdown from './cluster_form_dropdown.vue';

export default {
  components: {
    ClusterFormDropdown,
  },
  props: {
    vpcs: {
      type: Array,
      required: false,
      default: () => [],
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    error: {
      type: Object,
      required: false,
      default: null,
    },
  },
  computed: {
    hasErrors() {
      return Boolean(this.error);
    },
    helpText() {
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
};
</script>
<template>
  <div>
    <cluster-form-dropdown
      field-id="eks-vpc"
      field-name="eks-vpc"
      :items="vpcs"
      :loading="loading"
      :disabled="disabled"
      :disabled-text="s__('ClusterIntegration|Select a region to choose a VPC')"
      :loading-text="s__('ClusterIntegration|Loading VPCs')"
      :placeholder="s__('ClusterIntergation|Select a VPC')"
      :search-field-placeholder="s__('ClusterIntegration|Search VPCs')"
      :empty-text="s__('ClusterIntegration|No VPCs found')"
      :has-errors="hasErrors"
      :error-message="s__('ClusterIntegration|Could not load VPCs for the selected region')"
      v-bind="$attrs"
      v-on="$listeners"
    />
    <p class="form-text text-muted" v-html="helpText"></p>
  </div>
</template>
