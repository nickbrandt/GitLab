<script>
import { GlEmptyState } from '@gitlab/ui';
import createStore from '../store';

export default {
  name: 'CodeAnalytics',
  store: createStore(),
  components: {
    GlEmptyState,
  },
  props: {
    emptyStateSvgPath: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <gl-empty-state
    :title="__('Identify the most frequently changed files in your repository')"
    :description="
      __(
        'Identify areas of the codebase associated with a lot of churn, which can indicate potential code hotspots.',
      )
    "
    :svg-path="emptyStateSvgPath"
  />
</template>
