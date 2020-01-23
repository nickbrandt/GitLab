<script>
import { mapState, mapActions, mapGetters } from 'vuex';
import { GlButton, GlLoadingIcon } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  components: {
    GlButton,
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
  <div v-if="isActive" class="full-width prepend-bottom-32">
    <gl-button :disabled="isConfirmingOrder" variant="success" @click="confirmOrder">
      <gl-loading-icon v-if="isConfirmingOrder" inline size="sm" />
      {{ isConfirmingOrder ? $options.i18n.confirming : $options.i18n.confirm }}
    </gl-button>
  </div>
</template>
