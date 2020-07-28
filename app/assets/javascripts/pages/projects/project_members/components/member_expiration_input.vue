<script>
import { GlDatepicker } from '@gitlab/ui';

export default {
  components: {
    GlDatepicker,
  },
  props: {
    elId: {
      type: String,
      required: true,
    },
    disabled: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      isEditingCustom: false,
    };
  },
};
</script>

<template>
  <gl-datepicker>
    <input
      :id="elId"
      :disabled="disabled"
      class="gl-datepicker-input form-control"
      name="date"
      type="text"
      :aria-label="__('Expiration date')"
      :placeholder="__('Expiration date')"
    />
  </gl-datepicker>
</template>
