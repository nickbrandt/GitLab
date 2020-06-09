<script>
import { GlBadge, GlIcon, GlNewDropdown, GlNewDropdownItem } from '@gitlab/ui';
import dateFormat from 'dateformat';
import { __ } from '~/locale';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import query from '../queries/group_iteration.query.graphql';

export default {
  components: {
    GlBadge,
    GlIcon,
    GlNewDropdown,
    GlNewDropdownItem,
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
      update(data, errors) {
        if (errors) {
          return {};
        }

        const iteration = data.group.iterations.nodes[0] || {
          title: __('Iteration not found'),
          state: 'upcoming',
        };

        return {
          iteration,
          issues: data.group.issues.nodes,
        };
      },
    },
  },
  filters: {
    date: value => {
      if (!value) return '';
      const date = new Date(value);
      return dateFormat(date, 'mmm d, yyyy', true);
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
    editIterationPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      title: '',
      startDate: '',
      dueDate: '',
      group: {
        iteration: {},
        issues: [],
      },
    };
  },
  computed: {
    iteration() {
      return this.group.iteration;
    },
    issues() {
      return this.group.issues;
    },
    status() {
      switch (this.iteration.state) {
        case 'closed':
          return {
            text: __('Closed'),
            variant: 'danger',
          };
        case 'expired':
          return { text: __('Past due'), variant: 'warning' };
        case 'upcoming':
          return { text: __('Upcoming'), variant: 'neutral' };
        default:
          return { text: __('Open'), variant: 'success' };
      }
    },
  },
};
</script>

<template>
  <div>
    <div
      class="gl-display-flex gl-justify-items-center gl-align-items-center gl-py-3 gl-border-1 gl-border-b-solid gl-border-gray-200"
    >
      <gl-badge :variant="status.variant">
        {{ status.text }}
      </gl-badge>
      <span class="gl-ml-4">{{ iteration.startDate | date }} – {{ iteration.dueDate | date }}</span>
      <gl-new-dropdown
        v-if="canEdit"
        variant="default"
        toggle-class="gl-text-decoration-none gl-border-0! gl-shadow-none!"
        class="gl-ml-auto gl-text-secondary"
        right
        no-caret
      >
        <template #button-content>
          <gl-icon name="ellipsis_v" /><span class="sr-only">{{ __('Actions') }}</span>
        </template>
        <gl-new-dropdown-item :href="editIterationPath">{{
          __('Edit iteration')
        }}</gl-new-dropdown-item>
        <gl-new-dropdown-item
          ><span class="text-danger">{{ __('Delete iteration') }}</span></gl-new-dropdown-item
        >
      </gl-new-dropdown>
    </div>
    <h3 class="page-title">{{ iteration.title }}</h3>
    <div v-html="iteration.description"></div>
    <div v-for="issue in issues" :key="issue.title">{{ issue.assignes }}</div>
  </div>
</template>
