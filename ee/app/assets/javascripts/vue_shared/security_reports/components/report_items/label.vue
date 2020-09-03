<script>
import { GlIcon, GlFriendlyWrap } from '@gitlab/ui';
import { dynI8n } from "./dynamic_i8n";

export default {
  name: 'ReportItemLabel',
  components: {
    GlFriendlyWrap,
    GlIcon
  },
  props: {
    name: {
      type: Array,
      required: true,
    },
    description: {
      type: Array,
      required: false,
      default: ()=> [],
    }
  },
  computed: {
    nameText() {
      return dynI8n(this.name);
    },
    descriptionText() {
      return dynI8n(this.description);
    },
  },
}
</script>

<template>
  <tr>
    <td class="report-item-label-td">
        <label class="font-weight-bold">
          <gl-friendly-wrap :text="nameText" />
        </label>
        <span v-if="description.length > 0" :title="descriptionText">
          <gl-icon name="question" :size="12" />
        </span>
    </td>
  </tr>
</template>
