<script>
import { GlSkeletonLoader } from '@gitlab/ui';

export default {
  name: 'BoardCardLoading',
  components: {
    GlSkeletonLoader,
  },
};
</script>

<template>
  <div
    class="gl-mb-3 gl-bg-white gl-rounded-base gl-p-5"
    style="border: 1px solid #dfdfdf; box-shadow: 0 1px 2px rgba(0, 0, 0, 0.1); height: 110px"
  >
    <div style="width: 340px; height: 100px">
      <gl-skeleton-loader :width="340" :height="100">
        <rect width="340" height="16" rx="4" />
        <rect y="30" width="118" height="16" rx="8" />
        <rect x="122" y="30" width="130" height="16" rx="8" />
        <rect y="62" width="38" height="16" rx="4" />
        <circle cx="320" cy="68" r="16" />
      </gl-skeleton-loader>
    </div>
  </div>
</template>
