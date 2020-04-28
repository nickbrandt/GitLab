<script>
import { GlCard, GlSkeletonLoading } from '@gitlab/ui';

export default {
  name: 'MetricCard',
  components: {
    GlCard,
    GlSkeletonLoading,
  },
  props: {
    title: {
      type: String,
      required: true,
    },
    metrics: {
      type: Array,
      required: true,
    },
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
};
</script>

<template>
  <gl-card>
    <template #header>
      <strong ref="title">{{ title }}</strong>
    </template>
    <template #default>
      <gl-skeleton-loading v-if="isLoading" class="h-auto py-3" />
      <div v-else ref="metricsWrapper" class="d-flex">
        <div
          v-for="metric in metrics"
          :key="metric.key"
          ref="metricItem"
          class="js-metric-card-item flex-grow text-center"
        >
          <h3 class="my-2">
            <template v-if="metric.value === null"
              >-</template
            >
            <template v-else>{{ metric.value }}</template>
          </h3>
          <p class="text-secondary gl-font-sm mb-2">{{ metric.label }}</p>
        </div>
      </div>
    </template>
  </gl-card>
</template>
