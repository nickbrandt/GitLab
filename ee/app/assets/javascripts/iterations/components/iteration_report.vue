<script>
import { GlBadge, GlButton, GlIcon } from '@gitlab/ui';
import dateFormat from 'dateformat';
import { __ } from '~/locale';
import query from '../queries/group_iteration.query.graphql';

export default {
  components: {
    GlBadge,
    GlButton,
    GlIcon,
  },
  apollo: {
    iteration: {
      query,
      variables() {
        return {
          groupPath: this.groupPath,
          id: this.iterationId,
        };
      },
      update(data, errors) {
        // console.log(errors);
        return data.group.iterations.nodes[0];
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
  },
  data() {
    return {
      title: '',
      startDate: '',
      dueDate: '',
      iteration: {},
    };
  },
  computed: {
    status() {
      switch (this.iteration.state) {
        case 'closed':
          return {
            text: __('Closed'),
            style: 'danger',
          };
        case 'expired':
          return { text: __('Past due'), style: 'warning' };
        case 'upcoming':
          return { text: __('Upcoming'), style: 'secondary' };
        default:
          return { text: __('Open'), style: 'success' };
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
      <gl-button v-if="false" variant="link" class="gl-ml-auto gl-text-secondary">
        <gl-icon name="ellipsis_v" />
      </gl-button>
    </div>
    <h3 class="page-title">{{ iteration.title }}</h3>
    <div v-html="iteration.description"></div>
  </div>
</template>
