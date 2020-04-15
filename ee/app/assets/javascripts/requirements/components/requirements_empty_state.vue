<script>
import { GlEmptyState, GlDeprecatedButton } from '@gitlab/ui';
import { __ } from '~/locale';

import { FilterState, FilterStateEmptyMessage } from '../constants';

export default {
  components: {
    GlEmptyState,
    GlDeprecatedButton,
  },
  props: {
    filterBy: {
      type: String,
      required: true,
    },
    emptyStatePath: {
      type: String,
      required: true,
    },
    requirementsCount: {
      type: Object,
      required: true,
    },
  },
  computed: {
    emptyStateTitle() {
      return this.requirementsCount[FilterState.all]
        ? FilterStateEmptyMessage[this.filterBy]
        : __('Requirements allow you to create criteria to check your products against.');
    },
    emptyStateDescription() {
      return !this.requirementsCount[FilterState.all]
        ? __(
            `Requirements can be based on users, stakeholders, system, software
             or anything else you find important to capture.`,
          )
        : null;
    },
  },
};
</script>

<template>
  <div class="requirements-empty-state-container">
    <gl-empty-state
      :svg-path="emptyStatePath"
      :title="emptyStateTitle"
      :description="emptyStateDescription"
    >
      <template v-if="emptyStateDescription" #actions>
        <gl-deprecated-button
          category="primary"
          variant="success"
          @click="$emit('clickNewRequirement')"
          >{{ __('New requirement') }}</gl-deprecated-button
        >
      </template>
    </gl-empty-state>
  </div>
</template>
