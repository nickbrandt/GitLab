<script>
import { GlLink } from '@gitlab/ui';
import dateFormat from 'dateformat';

export default {
  components: {
    GlLink,
  },
  filters: {
    date: value => {
      const date = new Date(value);
      return dateFormat(date, 'mmm d, yyyy', true);
    },
  },
  props: {
    iterations: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
};
</script>

<template>
  <div class="milestones mt-0">
    <ul v-if="iterations.length > 0" class="content-list">
      <li v-for="iteration in iterations" :key="iteration.id" class="milestone">
        <div class="gl-mb-3">
          <gl-link :href="iteration.webPath"
            ><strong>{{ iteration.title }}</strong></gl-link
          >
        </div>
        <div class="text-secondary gl-mb-3">
          {{ iteration.startDate | date }}–{{ iteration.dueDate | date }}
        </div>
      </li>
    </ul>
    <div v-else class="nothing-here-block">
      {{ __('No iterations to show') }}
    </div>
  </div>
</template>
