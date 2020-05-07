<script>
import { GlButton, GlTab, GlTabs } from '@gitlab/ui';
import GroupIterationQuery from '../queries/group_iteration.query.graphql';

export default {
  components: {
    GlButton,
    GlTab,
    GlTabs,
  },
  props: {
    groupPath: {
      type: String,
      required: true,
    },
    canAdmin: {
      type: Boolean,
      required: false,
      default: false,
    },
    newIterationPath: {
      type: String,
      required: false,
      default: 'iterations/new', // TODO - get from BE
    },
  },
  apollo: {
    iterations: {
      query: GroupIterationQuery,
      update: data => data.group.sprints.nodes,
      variables() {
        return {
          fullPath: this.groupPath,
        };
      },
    },
  },
};
</script>

<template>
  <gl-tabs>
    <gl-tab>
      <template #title>
        {{ s__('Open') }}
      </template>
    </gl-tab>
    <template #tabs-end>
      <li class="ml-auto d-flex align-items-center">
        <gl-button variant="success" :href="newIterationPath">{{ __('New iteration') }}</gl-button>
      </li>
    </template>
  </gl-tabs>
</template>
