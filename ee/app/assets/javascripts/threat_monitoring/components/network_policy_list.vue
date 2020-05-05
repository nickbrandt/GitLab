<script>
import { mapState } from 'vuex';
import { GlTable, GlEmptyState } from '@gitlab/ui';
import { s__ } from '~/locale';
import { getTimeago } from '~/lib/utils/datetime_utility';
import { setUrlFragment } from '~/lib/utils/url_utility';
import EnvironmentPicker from './environment_picker.vue';

export default {
  components: {
    GlTable,
    GlEmptyState,
    EnvironmentPicker,
  },
  props: {
    documentationPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapState('networkPolicies', ['policies', 'isLoadingPolicies']),
    documentationFullPath() {
      return setUrlFragment(this.documentationPath, 'container-network-policy');
    },
  },
  methods: {
    getTimeAgoString(creationTimestamp) {
      return getTimeago().format(creationTimestamp);
    },
  },
  fields: [
    { key: 'name', label: s__('NetworkPolicies|Name'), thClass: 'w-75 font-weight-bold' },
    { key: 'status', label: s__('NetworkPolicies|Status'), thClass: 'font-weight-bold' },
    {
      key: 'creationTimestamp',
      label: s__('NetworkPolicies|Last modified'),
      thClass: 'font-weight-bold',
    },
  ],
  emptyStateDescription: s__(
    `NetworkPolicies|Policies are a specification of how groups of pods are allowed to communicate with each other network endpoints.`,
  ),
};
</script>

<template>
  <div>
    <div class="pt-3 px-3 bg-gray-light">
      <div class="row">
        <environment-picker ref="environmentsPicker" />
      </div>
    </div>

    <gl-table
      ref="policiesTable"
      :busy="isLoadingPolicies"
      :items="policies"
      :fields="$options.fields"
      head-variant="white"
      stacked="md"
      thead-class="gl-text-gray-900 border-bottom"
      tbody-class="gl-text-gray-900"
      show-empty
    >
      <template #cell(status)>
        {{ s__('NetworkPolicies|Enabled') }}
      </template>

      <template #cell(creationTimestamp)="value">
        {{ getTimeAgoString(value.item.creationTimestamp) }}
      </template>

      <template #empty>
        <slot name="emptyState">
          <gl-empty-state
            ref="tableEmptyState"
            :title="s__('NetworkPolicies|No policies detected')"
            :description="$options.emptyStateDescription"
            :primary-button-link="documentationFullPath"
            :primary-button-text="__('Learn More')"
          />
        </slot>
      </template>
    </gl-table>
  </div>
</template>
