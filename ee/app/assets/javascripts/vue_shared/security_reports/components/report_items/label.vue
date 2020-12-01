<script>
import { GlIcon, GlFriendlyWrap } from '@gitlab/ui';
import { dynI8n } from './dynamic_i8n';

export default {
  name: 'ReportLabel',
  components: {
    GlFriendlyWrap,
    GlIcon,
  },
  props: {
    name: {
      type: Array,
      required: true,
    },
    description: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  computed: {
    nameText() {
      return dynI8n(this.name);
    },
    descriptionText() {
      return dynI8n(this.description);
    },
  },
};
</script>

<template>
  <div>
    <label class="font-weight-bold">
      <gl-friendly-wrap :text="nameText" />
    </label>
    <span v-if="description.length > 0" :title="descriptionText">
      <gl-icon name="question" :size="12" class="gl-text-gray-500" />
    </span>
  </div>
</template>
