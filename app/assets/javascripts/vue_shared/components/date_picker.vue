<script>
import { GlDatepicker } from '@gitlab/ui';
import { __ } from '~/locale';

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
    label: {
      type: String,
      required: false,
      default: __('Date Picker'),
    },
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
      :aria-label="label"
      :placeholder="label"
    />
  </gl-datepicker>
</template>
