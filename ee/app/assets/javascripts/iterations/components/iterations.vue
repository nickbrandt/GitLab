<script>
import { GlButton, GlTab, GlTabs } from '@gitlab/ui';
import IterationsList from './iterations_list.vue';
import GroupIterationQuery from '../queries/group_iteration.query.graphql';

export default {
  components: {
    IterationsList,
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
      default: '',
    },
  },
  apollo: {
    iterations: {
      query: GroupIterationQuery,
      update: data => data.group.sprints.nodes,
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
      loading: 0,
      tabIndex: 0,
    };
  },
  computed: {
    state() {
      switch (this.tabIndex) {
        default:
        case 0:
          return 'opened';
        case 1:
          return 'closed';
        case 2:
          return undefined;
      }
    }
  },
};
</script>

<template>
  <gl-tabs v-model="tabIndex">
    <gl-tab>
      <template #title>
        {{ s__('Open') }}
      </template>
      <iterations-list
        :iterations="iterations"
        :loading="loading"
      />
    </gl-tab>
    <gl-tab>
       <template #title>
        {{ s__('Closed') }}
      </template>
      <iterations-list
        :iterations="iterations"
        :loading="loading"
      />
    </gl-tab>
    <gl-tab>
       <template #title>
        {{ s__('All') }}
      </template>
      <iterations-list
        :iterations="iterations"
        :loading="loading"
      />
    </gl-tab>
    <!-- TODO: check canAdmin or appropriate permission for create iteration -->
    <template #tabs-end>
      <li class="ml-auto d-flex align-items-center">
        <gl-button variant="success" :href="newIterationPath">{{ __('New iteration') }}</gl-button>
      </li>
    </template>
  </gl-tabs>
</template>
