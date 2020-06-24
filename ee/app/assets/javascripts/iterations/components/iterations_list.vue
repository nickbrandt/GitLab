<script>
import { GlLink } from '@gitlab/ui';
import { formatDate } from '~/lib/utils/datetime_utility';

export default {
  components: {
    GlLink,
  },
  props: {
    iterations: {
      type: Array,
      required: false,
      default: () => [],
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
  <div class="milestones mt-0">
    <ul v-if="iterations.length > 0" class="content-list">
      <li v-for="iteration in iterations" :key="iteration.id" class="milestone">
        <div class="gl-mb-3">
          <gl-link :href="iteration.webPath"
            ><strong>{{ iteration.title }}</strong></gl-link
          >
        </div>
        <div class="text-secondary gl-mb-3">
          {{ formatDate(iteration.startDate) }}–{{ formatDate(iteration.dueDate) }}
        </div>
      </li>
    </ul>
    <div v-else class="nothing-here-block">
      {{ __('No iterations to show') }}
    </div>
  </div>
</template>
