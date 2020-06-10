<script>
import { GlButton, GlLoadingIcon, GlTab, GlTabs } from '@gitlab/ui';
import IterationsList from './iterations_list.vue';
import GroupIterationQuery from '../queries/group_iterations.query.graphql';

export default {
  components: {
    IterationsList,
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
      default: '',
    },
  },
  apollo: {
    iterations: {
      query: GroupIterationQuery,
      update: data => data.group.iterations.nodes,
      variables() {
        return {
          fullPath: this.groupPath,
          state: this.state,
        };
      },
    },
  },
  data() {
    return {
      iterations: [],
      tabIndex: 0,
    };
  },
  computed: {
    loading() {
      return this.$apollo.queries.iterations.loading;
    },
    state() {
      switch (this.tabIndex) {
        default:
        case 0:
          return 'opened';
        case 1:
          return 'closed';
        case 2:
          return 'all';
      }
    },
  },
};
</script>

<template>
  <gl-tabs v-model="tabIndex">
    <gl-tab v-for="tab in [__('Open'), __('Closed'), __('All')]" :key="tab">
      <template #title>
        {{ tab }}
      </template>
      <div v-if="loading" class="gl-my-5">
        <gl-loading-icon size="lg" />
      </div>
      <iterations-list v-else :iterations="iterations" />
    </gl-tab>
    <template v-if="canAdmin" #tabs-end>
      <li class="gl-ml-auto gl-display-flex gl-align-items-center">
        <gl-button variant="success" :href="newIterationPath">{{ __('New iteration') }}</gl-button>
      </li>
    </template>
  </gl-tabs>
</template>
