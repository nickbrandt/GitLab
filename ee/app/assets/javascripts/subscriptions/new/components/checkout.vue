<script>
import { s__ } from '~/locale';
import ProgressBar from './checkout/progress_bar.vue';

export default {
  components: { ProgressBar },
  i18n: {
    checkout: s__('Checkout|Checkout'),
  },
};
</script>
<template>
  <div class="checkout d-flex flex-column justify-content-between w-100">
    <div class="full-width">
      <progress-bar :step="2" />
      <div class="flash-container"></div>
      <h2 class="mt-4 mb-3 mb-lg-5">{{ $options.i18n.checkout }}</h2>
    </div>
  </div>
</template>
