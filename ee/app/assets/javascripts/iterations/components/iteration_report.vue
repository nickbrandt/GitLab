<script>
import { GlAlert, GlBadge, GlLoadingIcon, GlEmptyState } from '@gitlab/ui';
import { formatDate } from '~/lib/utils/datetime_utility';
import { __ } from '~/locale';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import query from '../queries/group_iteration.query.graphql';

const iterationStates = {
  closed: 'closed',
  upcoming: 'upcoming',
  expired: 'expired',
};

export default {
  components: {
    GlAlert,
    GlBadge,
    GlLoadingIcon,
    GlEmptyState,
  },
  apollo: {
    group: {
      query,
      variables() {
        return {
          groupPath: this.groupPath,
          id: getIdFromGraphQLId(this.iterationId),
        };
      },
      update(data) {
        const iteration = data?.group?.iterations?.nodes[0] || {};

        return {
          iteration,
        };
      },
      error(err) {
        this.error = err.message;
      },
    },
  },
  props: {
    groupPath: {
      type: String,
      required: true,
    },
    iterationId: {
      type: String,
      required: true,
    },
    canEdit: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      error: '',
      group: {
        iteration: {},
      },
    };
  },
  computed: {
    iteration() {
      return this.group.iteration;
    },
    hasIteration() {
      return !this.$apollo.queries.group.loading && this.iteration?.title;
    },
    status() {
      switch (this.iteration.state) {
        case iterationStates.closed:
          return {
            text: __('Closed'),
            variant: 'danger',
          };
        case iterationStates.expired:
          return { text: __('Past due'), variant: 'warning' };
        case iterationStates.upcoming:
          return { text: __('Upcoming'), variant: 'neutral' };
        default:
          return { text: __('Open'), variant: 'success' };
      }
    },
  },
  methods: {
    formatDate(date) {
      return formatDate(date, 'mmm d, yyyy');
    },
  },
};
</script>

<template>
  <div>
    <gl-alert v-if="error" variant="danger" @dismiss="error = ''">
      {{ error }}
    </gl-alert>
    <gl-loading-icon v-if="$apollo.queries.group.loading" class="gl-py-5" size="lg" />
    <gl-empty-state
      v-else-if="!hasIteration"
      :title="__('Could not find iteration')"
      :compact="false"
    />
    <template v-else>
      <div
        ref="topbar"
        class="gl-display-flex gl-justify-items-center gl-align-items-center gl-py-3 gl-border-1 gl-border-b-solid gl-border-gray-200"
      >
        <gl-badge :variant="status.variant">
          {{ status.text }}
        </gl-badge>
        <span class="gl-ml-4"
          >{{ formatDate(iteration.startDate) }} – {{ formatDate(iteration.dueDate) }}</span
        >
      </div>
      <h3 ref="title" class="page-title">{{ iteration.title }}</h3>
      <div ref="description" v-html="iteration.description"></div>
    </template>
  </div>
</template>
