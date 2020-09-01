<script>
import ReportItemLabelValue from './label_value.vue';

export default {
  name: 'ReportItemLabel',
  components: {
    ReportItemLabelValue
  },
  props: {
    name: {
      type: String,
      required: true,
    },
    value: {
      type: String,
      required: true,
    },
  },
}
</script>

<template>
  <tr>
    <td class="report-item-label-td">
        <label class="font-weight-bold">{{name}}</label>
    </td>
    <td>
      <report-item-label-value :value="value" />
    </td>
  </tr>
</template>
