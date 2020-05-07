<script>
import { GlButton, GlLoadingIcon, GlTab, GlTabs } from '@gitlab/ui';
import GroupIterationQuery from '../queries/group_iteration.query.graphql';

export default {
  components: {
    GlButton,
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
    upcomingIterations: {
      query: GroupIterationQuery,
      update: data => data.group.sprints.nodes,
      variables() {
        return {
          fullPath: this.groupPath,
          state: 'upcoming',
        };
      },
    },
    inProgressIterations: {
      query: GroupIterationQuery,
      update: data => data.group.sprints.nodes,
      variables() {
        return {
          fullPath: this.groupPath,
          state: 'in_progress',
        };
      },
    },
    closedIterations: {
      query: GroupIterationQuery,
      update: data => data.group.sprints.nodes,
      variables() {
        return {
          fullPath: this.groupPath,
          state: 'closed',
        };
      },
    },
  },
  data() {
    return {
      upcomingIterations: [],
      inProgressIterations: [],
      closedIterations: [],
      loading: 0,
      tabIndex: 0,
    };
  },
  computed: {
    // TODO: these need to be combined in a single query
    iterations() {
      return [
        ...this.inProgressIterations,
        ...this.upcomingIterations,
      ];
    },
    query() {
      switch (this.tabIndex) {
        default:
        case 0:
          return 'open';
        case 1:
          return 'closed';
        case 2:
          return 'all';
      }
    }
  },
};
</script>

<template>
  <gl-tabs v-model="tabIndex">
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
    <gl-tab>
       <template #title>
        {{ s__('Closed') }}
      </template>
    </gl-tab>
    <gl-tab>
       <template #title>
        {{ s__('All') }}
      </template>
    </gl-tab>
    <template #tabs-end>
      <li class="ml-auto d-flex align-items-center">
        <gl-button variant="success" :href="newIterationPath">{{ __('New iteration') }}</gl-button>
      </li>
    </template>
  </gl-tabs>
</template>
