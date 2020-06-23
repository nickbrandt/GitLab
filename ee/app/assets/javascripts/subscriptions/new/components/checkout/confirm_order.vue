<script>
import { mapState, mapActions, mapGetters } from 'vuex';
import { GlDeprecatedButton, GlLoadingIcon } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  components: {
    GlDeprecatedButton,
    GlLoadingIcon,
  },
  computed: {
    ...mapState(['isConfirmingOrder']),
    ...mapGetters(['currentStep']),
    isActive() {
      return this.currentStep === 'confirmOrder';
    },
  },
  methods: {
    ...mapActions(['confirmOrder']),
  },
  i18n: {
    confirm: s__('Checkout|Confirm purchase'),
    confirming: s__('Checkout|Confirming...'),
  },
};
</script>
<template>
  <div v-if="isActive" class="full-width gl-mb-7">
    <gl-deprecated-button :disabled="isConfirmingOrder" variant="success" @click="confirmOrder">
      <gl-loading-icon v-if="isConfirmingOrder" inline size="sm" />
      {{ isConfirmingOrder ? $options.i18n.confirming : $options.i18n.confirm }}
    </gl-deprecated-button>
  </div>
</template>
