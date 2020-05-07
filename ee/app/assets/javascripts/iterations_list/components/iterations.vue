<script>
import { GlButton, GlEmptyState, GlLoadingIcon, GlTab, GlTabs } from '@gitlab/ui';
import GroupIterationQuery from '../queries/group_iteration.query.graphql';

export default {
  components: {
    GlButton,
    GlEmptyState,
    GlLoadingIcon,
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
  data() {
    return {
      iterations: [],
      loading: 0,
    };
  },
};
</script>

<template>
  <gl-tabs>
    <gl-tab class="milestones">
      <template #title>
        {{ s__('Open') }}
      </template>
      <div v-if="loading">
        <gl-loading-icon size="lg" />
      </div>
      <ul v-else-if="iterations.length > 0" class="content-list">
        <li v-for="iteration in iterations" :key="iteration.id" class="milestone milestone-open">
          <strong>{{ iteration.title }}</strong>
          <p class="text-secondary">{{ iteration.startDate }} - {{ iteration.dueDate }}</p>
        </li>
      </ul>
      <div v-else class="nothing-here-block">
        {{ __('No iterations to show') }}
      </div>
    </gl-tab>
    <template #tabs-end>
      <li class="ml-auto d-flex align-items-center">
        <gl-button variant="success" :href="newIterationPath">{{ __('New iteration') }}</gl-button>
      </li>
    </template>
  </gl-tabs>
</template>
