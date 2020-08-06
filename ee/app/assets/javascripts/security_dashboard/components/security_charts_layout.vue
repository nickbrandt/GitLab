<script>
import { s__ } from '~/locale';

export default {
  i18n: {
    title: s__('SecurityReports|Security Dashboard'),
  },
};
</script>

<template functional>
  <div>
    <h1>{{ $options.i18n.title }}</h1>
    <div class="security-charts gl-display-flex gl-flex-wrap">
      <slot></slot>
    </div>
  </div>
</template>
