<script>
import { GlDeprecatedButton } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  components: {
    GlDeprecatedButton,
  },
  props: {
    isEditable: {
      type: Boolean,
      required: true,
    },
    edit: {
      type: Function,
      required: true,
    },
  },
  i18n: {
    edit: s__('Checkout|Edit'),
  },
};
</script>
<template>
  <div class="overview d-flex justify-content-between">
    <div>
      <slot></slot>
    </div>
    <div v-if="isEditable" class="d-flex flex-column justify-content-center">
      <gl-deprecated-button @click="edit">{{ $options.i18n.edit }}</gl-deprecated-button>
    </div>
  </div>
</template>
